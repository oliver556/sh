#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 交互辅助函数
# 
# @文件路径: lib/guards/check.sh
# @功能描述: 检查 + 提示（不修复）
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: require_supported_os
# 功能:   检测是否为所支持的系统版本
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 支持
#   1 - 不支持
# 
# 示例:
#   require_supported_os
# ------------------------------------------------------------------------------
check_supported_os() {
    local os
    os=$(get_os_type)
    if [[ "$os" != "debian" ]]; then
        ui_error "当前系统不受支持: $os"
        ui_tip "仅支持 Debian 系列系统（Debian / Ubuntu）"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: check_root
# 功能:   检查是否为 root（带提示）
# 
# 参数: 无
# 
# 返回值:
#   0 - 通过（root 用户）
#   1 - 未通过（普通用户）
#
# 示例 1: 可中断式（推荐）
#     check_root || return
#
# 示例 2: 可中断式
#     if ! check_root; then
#         return
#     fi
# 示例 3: 非交互 / CI / 静默模式
#     if ! is_root; then
#         echo "This script must be run as root" >&2
#         exit 1
#     fi
# ------------------------------------------------------------------------------
check_root() {
    is_root && return 0

    ui_error "该功能需要使用 root 用户才能运行此脚本"
    ui blank
    ui_tip "请切换到 'root' 用户来执行。"
    
    ui_wait_enter
    
    return 1
}

# ------------------------------------------------------------------------------
# 函数名: check_cmd
# 功能:   基于 check_cmd 的语义化封装
# 
# 参数:
#   $1 (string): 命令名称 (如 wget, curl, git) (必填)
# 
# 返回值:
#   0 - 已安装
#   1 - 未安装
# 
# 示例 1: 纯判断
#     if has_cmd wget; then
#         ...
#     fi
# 
# 示例 2: guard
#     check_cmd wget || return
# 
# 示例 3: 自动补齐
#     check_cmd curl || exit 1
# ------------------------------------------------------------------------------
check_cmd() {
    local cmd="$1"

    if [ -z "$cmd" ]; then
        ui_error "check_cmd: 缺少命令名称参数"
        return 1
    fi

    has_cmd "$cmd" && return 0

    ui_error "未检测到命令: $cmd"
    ui_tip   "请先安装该依赖后再继续"
    ui_wait_enter
    return 1
}
