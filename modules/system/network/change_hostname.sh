#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统主机名修改
#
# @文件路径: modules/system/network/change_hostname.sh
# @功能描述: 修改系统 Hostname，自动同步 /etc/hosts，支持 Alpine/Systemd
#
# @作者: Jamison
# @版本: 1.0.0
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: _draw_hostname_status
# 功能:   绘制当前主机名状态面板
# ------------------------------------------------------------------------------
_draw_hostname_status() {
    local current_hostname
    current_hostname=$(uname -n)
    
    local kernel_ver
    kernel_ver=$(uname -r)

    local arch
    arch=$(uname -m)

    # 第一行: 主机名
    print_status_item -l "当前主机名:" -v "${GREEN}${current_hostname}${NC}" -w 12 -W 24
    # 第二行: 架构信息
    print_status_item -l "系统架构:" -v "${WHITE}${arch}${NC}" -w 10
    print_status_done
    
    # 第三行: 内核版本
    print_status_item -l "内核版本:" -v "${CYAN}${kernel_ver}${NC}" -w 12
    print_status_done
}

# ------------------------------------------------------------------------------
# 函数名: set_hostname_logic
# 功能:   执行系统主机名修改的核心逻辑
# 参数:   $1 (string) - 新主机名
# ------------------------------------------------------------------------------
set_hostname_logic() {
    local new_hostname="$1"
    local old_hostname
    old_hostname=$(uname -n)

    print_clear
    print_box_info -m "正在设置主机名为: ${BOLD_YELLOW}${new_hostname}${NC}" -s start

    # 1. 修改系统 Hostname (分系统处理)
    if [ -f /etc/alpine-release ]; then
        # --- Alpine Linux ---
        print_step -m "检测到 Alpine Linux..."
        echo "$new_hostname" > /etc/hostname
        hostname "$new_hostname"
    else
        # --- Systemd (Debian/Ubuntu/CentOS) ---
        print_step -m "使用 hostnamectl 设置..."
        
        # 尝试标准方法
        if command -v hostnamectl &>/dev/null; then
            hostnamectl set-hostname "$new_hostname"
        else
            # 兜底：如果没有 hostnamectl，手动修改
            hostname "$new_hostname"
            echo "$new_hostname" > /etc/hostname
        fi

        # 手动替换 /etc/hostname 中的旧名称 (双重保险)
        if [ -f /etc/hostname ]; then
            sed -i "s/$old_hostname/$new_hostname/g" /etc/hostname
        fi
        
        # 重启 hostnamed 服务 (如果存在)
        if systemctl list-units --full -all | grep -q "systemd-hostnamed.service"; then
            systemctl restart systemd-hostnamed
        fi
    fi

    # 2. 修改 /etc/hosts (确保 sudo/curl 等命令不报错)
    print_step -m "更新 /etc/hosts 映射..."
    
    # IPv4 处理
    if grep -q "127.0.0.1" /etc/hosts; then
        # 替换整行，确保格式正确
        sed -i "s/^127.0.0.1.*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
    else
        # 如果不存在则追加
        echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >> /etc/hosts
    fi

    # IPv6 处理
    if grep -q "^::1" /etc/hosts; then
        sed -i "s/^::1.*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
    else
        echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >> /etc/hosts
    fi

    # 3. 结果反馈
    if [[ "$(uname -n)" == "$new_hostname" ]]; then
        print_box_success -m "主机名修改成功！"
        print_key_value -k "旧主机名" -v "${old_hostname}"
        print_key_value -k "新主机名" -v "${new_hostname}"
        print_blank
        print_box_header_tip "可能需要重新连接 SSH 终端才会显示新的主机名提示符。"
    else
        print_box_error -m "主机名修改似乎未生效，请手动检查。"
    fi
    
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: change_hostname
# 功能:   系统主机名修改主菜单
# ------------------------------------------------------------------------------
change_hostname() {
    # 权限检查
    check_root || return

    while true; do
        print_clear
        print_box_header "修改系统主机名 (Hostname)"
        
        print_line
        _draw_hostname_status

        print_box_info -s start -m "系统主机名修改"
        print_info -m "请遵循域名命名规范 (仅允许字母、数字、连字符)（输入 0 退出）"
        
        local input
        input=$(read_choice -s 1 -m "请输入新的主机名")

        # 退出判断
        if [[ "$input" == "0" ]]; then
            return
        fi

        # 输入校验：非空
        if [[ -z "$input" ]]; then
            print_error -m "主机名不能为空！"
            sleep 1
            continue
        fi

        # 输入校验：正则 (字母数字横杠)
        if [[ ! "$input" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            print_error -m "主机名包含非法字符！建议仅使用字母、数字和 '-'"
            sleep 2
            continue
        fi

        # 执行修改
        set_hostname_logic "$input"
        # 修改完后通常直接返回，或者让用户看一眼新状态
        # 这里选择 loop continue 以便用户看到 _draw_hostname_status 刷新后的结果
    done
}