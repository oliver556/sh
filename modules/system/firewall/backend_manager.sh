#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 防火墙后端切换
#
# @文件路径: modules/system/firewall/backend_manager.sh
# @功能描述: 提供防火墙后端切换
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-02-04
# ==============================================================================

# shellcheck disable=SC1091
source "${BASE_DIR}/lib/package.sh"

# 简单的后端切换逻辑
firewall_switch_backend_ui() {
    print_clear
    print_box_info -m "切换防火墙后端"
    print_echo "${YELLOW}注意：切换后端可能会导致当前的临时规则丢失，建议切换后重新检查规则。${NC}"
    print_blank
    
    print_echo "请选择要启用的防火墙后端："
    print_echo "1. ${BOLD_GREEN}UFW${NC} (Ubuntu/Debian 推荐，简单易用)"
    print_echo "2. ${BOLD_GREEN}IPTables${NC} (纯净模式，高性能，CentOS/专家推荐)"
    print_echo "0. 取消"
    
    local choice
    choice=$(read_choice -s 1)
    
    case "$choice" in
        1) _switch_to_ufw ;;
        2) _switch_to_iptables ;;
        *) return ;;
    esac
}

_switch_to_ufw() {
    print_step "正在切换至 UFW..."
    
    # 1. 安装 UFW
    pkg_install "ufw"
    
    # 2. 停用其他
    systemctl stop firewalld 2>/dev/null
    systemctl disable firewalld 2>/dev/null
    
    # 3. 启用 UFW
    ufw --force enable
    systemctl enable ufw
    systemctl start ufw
    
    # 4. 保底：放行 SSH
    local ssh_port
    ssh_port=$(ssh_get_port 2>/dev/null || echo 22)
    ufw allow "$ssh_port"/tcp
    
    print_success "已切换至 UFW。SSH 端口 ($ssh_port) 已放行。"
    print_wait_enter
}

_switch_to_iptables() {
    print_step "正在切换至纯 IPTables..."
    
    # 1. 停用 UFW / Firewalld
    ufw --force disable 2>/dev/null
    systemctl stop ufw 2>/dev/null
    systemctl disable ufw 2>/dev/null
    
    systemctl stop firewalld 2>/dev/null
    systemctl disable firewalld 2>/dev/null
    
    # 2. 安装 iptables-persistent (Debian/Ubuntu) 或 iptables-services (CentOS)
    # 这里需要根据系统判断，简单写：
    pkg_install "iptables"
    
    # 3. 确保基础规则
    # ... (调用 reset 逻辑或者 flush logic)
    
    print_success "已切换至纯 IPTables 模式。"
    print_wait_enter
}