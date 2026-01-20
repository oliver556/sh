#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - Swap 管理核心逻辑
#
# @文件路径: modules/system/memory/swap.sh
# @功能描述: 安全创建 / 删除 / 管理 /swapfile 虚拟内存
#
# ⚠️ 设计原则：
#   - 仅操作 /swapfile
#   - 绝不自动处理 /dev/* swap 分区
#   - 高风险操作必须可控、可回滚
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-14
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************
source "${BASE_DIR}/lib/system_mem.sh"

# ------------------------------------------------------------------------------
# 函数名: swap_status
# 功能:   显示当前 Swap 状态
#
# 参数:
#   无
#
# 返回值:
#   无
#
# 示例:
#   swap_status
# ------------------------------------------------------------------------------
swap_status() {
    # 读取 swap 总量（KB）
    local total used percent

    # 单位：KB
    total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    used=$(awk '
        /SwapTotal/ {t=$2}
        /SwapFree/  {f=$2}
        END {print t-f}
    ' /proc/meminfo)

    # 未开启 Swap
    if [[ -z "$total" || "$total" -eq 0 ]]; then
        print_info -m "当前虚拟内存: 0M / 0M (0%)"
        return 0
    fi

    percent=$(( used * 100 / total ))

    print_info "当前虚拟内存: $((used / 1024))M / $((total / 1024))M (${percent}%)"
}

# ------------------------------------------------------------------------------
# 函数名: _swap_check_env
# 功能:   Swap 操作前的统一环境检查
#
# 参数:
#   无
#
# 返回值:
#   0 - 通过
#   1 - 失败
# ------------------------------------------------------------------------------
_swap_check_env() {
    check_root || return 1

    for cmd in fallocate mkswap swapon swapoff; do
        if ! command -v "$cmd" &>/dev/null; then
            print_error -m "缺少必要命令: $cmd"
            return 1
        fi
    done
}

# ------------------------------------------------------------------------------
# 函数名: swap_create
# 功能:   创建或重建 /swapfile
#
# 参数:
#   $1 (number): Swap 大小，单位 MB
#
# 返回值:
#   0 - 成功
#   1 - 失败
#
# 示例:
#   swap_create 2048
# ------------------------------------------------------------------------------
swap_create() {
    print_box_info -s start -m "创建 Swap (虚拟内存)..."

    local size="$1"

    _swap_check_env || return 1

    # 参数校验
    if [[ -z "$size" || ! "$size" =~ ^[0-9]+$ ]]; then
        print_error -m "Swap 大小参数无效"
        return 1
    fi

    # 若已存在 swapfile，先安全关闭
    if swapon --show | grep -q "^/swapfile"; then
        print_step "检测到已启用的 /swapfile，正在关闭..."
        swapoff /swapfile || {
            print_error -m "关闭现有 swapfile 失败"
            return 1
        }
    fi

    # 删除旧 swapfile
    if [[ -f /swapfile ]]; then
        print_step "移除旧的 /swapfile"
        rm -f /swapfile || return 1
    fi

    print_step "创建新的 /swapfile (${size}MB)"
    fallocate -l "${size}M" /swapfile || return 1
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null || return 1
    swapon /swapfile || return 1

    # 安全更新 fstab
    sed -i '/\/swapfile/d' /etc/fstab
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # Alpine Linux 特殊处理
    if [[ -f /etc/alpine-release ]]; then
        print_step "检测到 Alpine Linux，配置 swap 自启脚本"
        mkdir -p /etc/local.d
        echo "swapon /swapfile" > /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local >/dev/null 2>&1
    fi

    print_box_success --status finish --msg "创建 Swap (虚拟内存)，已成功设置为 ${size}MB"
}

# ------------------------------------------------------------------------------
# 函数名: swap_remove
# 功能:   关闭并移除 /swapfile
#
# 参数:
#   无
#
# 返回值:
#   0 - 成功
#   1 - 失败
#
# 示例:
#   swap_remove
# ------------------------------------------------------------------------------
swap_remove() {
    _swap_check_env || return 1

    print_box_info -s start -m "删除 Swap..."

    if ! [[ -f /swapfile ]]; then
        print_warn "/swapfile 不存在，无需移除"
        return 0
    fi

    print_step "正在关闭并删除 /swapfile..."

    if swapon --show | grep -q "^/swapfile"; then
        swapoff /swapfile || {
            print_error -m "关闭 swapfile 失败"
            return 1
        }
    fi

    rm -f /swapfile
    sed -i '/\/swapfile/d' /etc/fstab

    print_box_success --status finish --msg "删除 Swap"
}

# ------------------------------------------------------------------------------
# 函数名: swap_disable
# 功能:   关闭当前系统中所有已启用的 Swap（不删除文件）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 关闭成功或本就未启用
#   1 - 关闭失败
# 
# 示例:
#   swap_disable
# ------------------------------------------------------------------------------
swap_disable() {
    check_root || return 1

    # 是否存在已启用的 swap
    if ! swapon --summary | grep -q .; then
        print_box_info -m "当前未启用任何 Swap" "bottom"
        return 0
    fi

    print_box_info -s start -m "关闭 Swap..."

    print_step "检测到已启用的 Swap，正在关闭..."

    if swapoff -a; then
        print_box_success -s finish -m "关闭 Swap（未删除 Swap 文件）"
        return 0
    else
        print_box_error -m "关闭 Swap 失败" "all"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: swap_create_interactive
# 功能:   交互式创建 Swap（自定义大小，单位 MB）
# ------------------------------------------------------------------------------
swap_create_interactive() {
    print_box_info -s start -m "自定义 Swap"

    local size

    size=$(read_choice -s 1 -m "请输入 Swap 大小（单位：MB，输入 0 表示关闭 Swap）")

    # 空输入
    if [[ -z "$size" ]]; then
        print_error "$(print_spaces 1)未输入任何内容，已取消"
        return 1
    fi

    # 非数字
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        print_error "请输入有效的数字"
        return 1
    fi

    # 0 = 关闭 Swap
    if [[ "$size" -eq 0 ]]; then
        swap_disable
        return $?
    fi

    # 最小限制（可选）
    if [[ "$size" -lt 128 ]]; then
        print_warn "Swap 最小建议为 128MB"
        return 1
    fi

    print_blank

    swap_create "$size"
}

# ------------------------------------------------------------------------------
# 函数名: swap_get_suggested_info
# 功能:   获取 Swap 建议配置信息（数值与理由）
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - "建议值M (推荐理由)"
#   失败 - "1024M (通用 VPS 推荐)"
# 
# 示例:
#   info=$(swap_get_suggested_info)
# ------------------------------------------------------------------------------
swap_get_suggested_info() {
    local mem_mb suggest_size reason
    mem_mb=$(mem_get_total_mb)

    if [[ -z "$mem_mb" || "$mem_mb" -le 0 ]]; then
        suggest_size=1024
        reason="无法获取内存信息，使用通用建议"
    elif (( mem_mb <= 1024 )); then
        # 针对 1G 左右的机器，直接建议 2048M 看起来更专业
        suggest_size=2048
        reason="小内存 VPS，防止 OOM"
    elif (( mem_mb <= 2048 )); then
        suggest_size=2048
        reason="通用 VPS 推荐"
    elif (( mem_mb <= 4096 )); then
        suggest_size=4096
        reason="中等内存，平衡性能"
    else
        suggest_size=4096
        reason="大内存，仅作安全缓冲"
    fi

    print_echo "${suggest_size}M (${reason})"
}