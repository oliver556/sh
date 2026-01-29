#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 修改 SSH 端口
#
# @文件路径: modules/system/network/change_ssh_port.sh
# @功能描述: 修改 SSH 服务的监听端口，支持端口有效性验证和自动重启 SSH
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-13
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: set_ssh_port
# 功能:   设置 SSH 端口，接收端口号参数，直接执行修改和重启
# 
# 参数:
#   $1 (string): 目标端口号
#
# 返回值:
#   0 - 成功
#   1 - 失败
#
# 示例:
#   set_ssh_port 12222
# ------------------------------------------------------------------------------
set_ssh_port() {
    local target_port="$1"

    # 参数校验
    if [[ ! "$target_port" =~ ^[0-9]+$ ]]; then
        print_error "端口号必须是数字: $target_port"
        return 1
    fi

    if [[ "$target_port" -lt 1 || "$target_port" -gt 65535 ]]; then
        print_error "端口号超出范围 (1-65535): $target_port"
        return 1
    fi

    print_step "正在修改 SSH 配置文件..."
    
    # 确保 sshd_config 存在
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        print_error "找不到 /etc/ssh/sshd_config"
        return 1
    fi

    # 先把可能被注释掉的 #Port 解开，确保下一行 sed 能匹配到
    sed -i 's/^\s*#Port\s*/Port /' /etc/ssh/sshd_config
    
    # 替换端口号
    sed -i "s/^Port .*/Port $target_port/" /etc/ssh/sshd_config

    # 重启服务
    print_step "正在重启 SSH 服务..."
    if systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null; then
        print_success "SSH 端口已成功修改为: ${BOLD_GREEN}$target_port${NC}"
        print_echo "${YELLOW}提示：${NC}请确保您的防火墙/安全组已放行该端口，否则您将无法连接！"
        return 0
    else
        print_error "SSH 服务重启失败！请手动检查配置。"
        # 尝试回滚? 这里暂不回滚，保留现场供检查
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: change_ssh_port
# 功能:   修改 SSH 端口（行为型函数）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - SSH 端口修改成功
#   1 - 修改失败
#   2 - 用户取消操作
# 
# 示例:
#   change_ssh_port
# ------------------------------------------------------------------------------
change_ssh_port() {
    if ! check_root; then return 1; fi

    if [[ ! -f /etc/ssh/sshd_config ]]; then
        print_error -m "未找到 /etc/ssh/sshd_config"
        return 1
    fi

    print_clear
    
    # 预处理：确保能读取到当前端口
    sed -i 's/^\s*#Port\s*/Port /' /etc/ssh/sshd_config

    while true; do
        print_clear
        print_box_header "修改SSH端口"
        # 获取当前 SSH 端口用于展示
        local current_port
        current_port=$(grep -E '^Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
        print_echo "当前的 SSH 端口号是: ${BOLD_YELLOW}${current_port}${NC}"

        print_box_info -s start -m "修改 SSH 端口"
        print_info -m "端口号范围: 1 到 65535 之间的数字（输入 0 退出）"

        local choice
        choice=$(read_choice -s 1 -m "请输入新的 SSH 端口")

        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            print_error -m "输入无效，请输入数字"
            sleep 2
            continue
        fi

        if [[ "$choice" -eq 0 ]]; then
            print_info -m "操作已取消"
            print_blank
            return 2
        fi
    done
}