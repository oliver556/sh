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
# 函数名: ssh_change_ssh_port
# 功能:   修改 SSH 端口前的前置检查
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 可以执行修改
#   1 - 不满足条件（非 root / sshd 不存在）
# 
# 示例:
#   ssh_change_ssh_port
# ------------------------------------------------------------------------------
guard_change_ssh_port() {
    ui clear

    if ! check_root; then
        return 1
    fi

    # 必须存在 sshd_config 文件
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        ui_error "未找到 /etc/ssh/sshd_config 文件，无法修改 SSH 端口"
        return 1
    fi

    change_ssh_port
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
# 函数名: ssh_change_ssh_port
# 功能:   修改 SSH 端口前的前置检查
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 可以执行修改
#   1 - 不满足条件（非 root / sshd 不存在）
# 
# 示例:
#   ssh_change_ssh_port
# ------------------------------------------------------------------------------
guard_change_ssh_port() {
    ui clear

    if ! check_root; then
        return 1
    fi

    # 必须存在 sshd_config 文件
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        ui_error "未找到 /etc/ssh/sshd_config 文件，无法修改 SSH 端口"
        return 1
    fi

    change_ssh_port
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
    # 清理注释并确保 Port 指令可用
    sed -i 's/^\s*#Port\s*/Port /' /etc/ssh/sshd_config

    while true; do
        ui clear
        # 获取当前 SSH 端口
        local current_port
        current_port=$(grep -E '^Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

        ui line
        ui_info "当前的 SSH 端口号是: ${BOLD_YELLOW}${current_port}${RESET}"
        ui line
        ui echo "端口号范围: 1 到 65535 之间的数字（输入 0 退出）"

        local choice
        choice=$(ui_read_choice "请输入新的 SSH 端口号")

        # 如果不是数字，提示错误并重新循环
        if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
            ui_error "输入无效，请输入数字"
            sleep 2
            continue
        fi

        # 用户取消
        if [[ "$choice" -eq 0 ]]; then
            ui_info "取消修改 SSH 端口"
            return 2
        fi

        # 用户输入有效端口
        if [[ "$choice" -ge 1 && "$choice" -le 65535 ]]; then
            sed -i "s/^Port .*/Port $choice/" /etc/ssh/sshd_config
            if systemctl restart sshd 2>/dev/null || service ssh restart 2>/dev/null; then
                ui_success "SSH 端口已成功修改为 ${BOLD_GREEN}$choice${RESET}"
                return 0
            else
                ui_error "SSH 服务重启失败，请手动检查 sshd"
                ui_wait_enter
                return 1
            fi
        else
            # 超范围数字
            ui_error "端口号无效，请输入 1 到 65535 之间的数字"
            sleep 2
            continue
        fi
    done
}
