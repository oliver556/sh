#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 开启 root 登录
#
# @文件路径: modules/system/security/enable_root_login.sh
# @功能描述:
#   启用系统 root 用户登录能力（主要针对 SSH 登录）
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-12
# ==============================================================================

# TODO 待决定是否使用

# ------------------------------------------------------------------------------
# 函数名: guard_enable_root_login
# 功能:   开启 root 登录前的前置检查（守卫函数）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 允许执行开启 root 登录操作
#   1 - 不满足执行条件
# 
# 示例:
#   guard_enable_root_login
# ------------------------------------------------------------------------------
guard_enable_root_login() {
    if ! check_root; then
        return 1
    fi

    # --------------------------------------------------------------------------
    # 检查 sshd 配置文件是否存在
    # --------------------------------------------------------------------------
    if [[ ! -f /etc/ssh/sshd_config ]]; then
        ui_error "未检测到 sshd_config，可能未安装 SSH 服务"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 函数名: enable_root_login
# 功能:   启用 root 用户登录（行为型）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 启用成功
#   1 - 启用失败
# 
# 示例:
#   enable_root_login
# ------------------------------------------------------------------------------
enable_root_login() {

    local sshd_config="/etc/ssh/sshd_config"

    ui_info "正在配置 SSH，开启 root 登录权限..."

    # --------------------------------------------------------------------------
    # 处理 PermitRootLogin 配置项
    # - 如果存在则替换
    # - 如果不存在则追加
    # --------------------------------------------------------------------------
    if grep -Eq '^[#\s]*PermitRootLogin' "$sshd_config"; then
        # 已存在配置项（含被注释的情况），统一替换
        sed -i 's/^[#\s]*PermitRootLogin.*/PermitRootLogin yes/' "$sshd_config"
    else
        # 不存在配置项，直接追加
        echo "PermitRootLogin yes" >> "$sshd_config"
    fi

    # --------------------------------------------------------------------------
    # 校验配置文件语法（防止写坏）
    # --------------------------------------------------------------------------
    if ! sshd -t &>/dev/null; then
        ui_error "sshd 配置校验失败，未应用更改"
        return 1
    fi

    # --------------------------------------------------------------------------
    # 重载 SSH 服务（不中断当前连接）
    # --------------------------------------------------------------------------
    if systemctl list-units --type=service | grep -q sshd.service; then
        systemctl reload sshd
    elif systemctl list-units --type=service | grep -q ssh.service; then
        systemctl reload ssh
    else
        ui_warn "未检测到可重载的 SSH 服务，请手动重启 sshd"
    fi

    ui_success "root 登录已启用（PermitRootLogin yes）"
    return 0
}
