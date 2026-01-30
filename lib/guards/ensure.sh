#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 交互辅助函数
# 
# @文件路径: lib/guards/ensure.sh
# @功能描述: 尝试安装保障（可失败）
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: ensure_cmd
# 功能:   安装对应命令
# 
# 参数:
#   $1 (string): 需要安装的命令名
#   $2 (string): has_cmd 的检查是否用对应函数的提示
# 
# 返回值:
#   0 - 安装成功
#   1 - 安装失败
# 
# 示例:
#   ensure_cmd
# ------------------------------------------------------------------------------
ensure_cmd() {
  	local cmd="$1"
    local pkg="${2:-$1}"  # 如果 $2 为空，则 pkg = cmd

  	has_cmd "$cmd" && return 0

  	print_warn -m "未检测到命令: $cmd，正在尝试安装..."

    install_cmd "$cmd" "$pkg" || {
        print_error -m "安装 $pkg 失败，请手动检查网络或源设置。"
        return 1
    }

  return 0
}

# ------------------------------------------------------------------------------
# 函数名: install_cmd
# 功能:   安装对应的环境
# 
# 参数:
#   $1 (string): 环境名 (必填)
# 
# 返回值:
#   0 - 已安装
#   1 - 未安装
# 
# 示例:
#   install_cmd "$1"
# ------------------------------------------------------------------------------
install_cmd() {
    local cmd="$1"
    local pkg="${2:-$1}"

    local SUDO_CMD=""

    # 1. 如果当前用户 ID 不是 0 (不是 root)，则命令前必须加 sudo
    if [ "$(id -u)" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi

    # 已安装直接返回
    has_cmd "$cmd" && return 0

    if is_debian_like; then
        # 2. 这里的指令变成 $SUDO_CMD apt-get ...
        # 如果是 root，变量为空，执行：apt-get update
        # 如果是普通用户，变量为 sudo，执行：sudo apt-get update
        $SUDO_CMD apt-get update -qq
        $SUDO_CMD apt-get install -y "$pkg" || return 1
        
    elif is_rhel; then
        if command -v dnf >/dev/null 2>&1; then
            $SUDO_CMD dnf install -y "$pkg" || return 1
        else
            $SUDO_CMD yum install -y "$pkg" || return 1
        fi
        
    elif is_alpine; then
        $SUDO_CMD apk add --no-cache "$pkg" || return 1
        
    else
        print_warn -m "当前系统不支持自动安装: $pkg"
        return 1
    fi

    # 二次检查
    has_cmd "$cmd" || return 1
}