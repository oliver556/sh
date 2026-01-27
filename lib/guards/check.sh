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
        print_error -m "当前系统不受支持: $os"
        ptint_info -m "仅支持 Debian 系列系统（Debian / Ubuntu）"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: check_root
# 功能:   检查是否为 root（带提示）
# 
# # 参数:
#   无
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
#     if ! check_root; then
#         echo "This script must be run as root" >&2
#         exit 1
#     fi
# ------------------------------------------------------------------------------
check_root() {
    is_root && return 0
    print_error -m "该功能需要使用 root 用户才能运行此脚本"
    print_blank
    print_info -m "请切换到 'root' 用户来执行。"
    print_wait_enter
    return 1
}

# ------------------------------------------------------------------------------
# 函数名: check_cmd
# 功能:   检查是否安装对应环境
# 
# 参数:
#   $1 (string) : 要检测的命令名称 (必填)
#   $2 (bool)   : 是否显示提示信息（可选，默认 false）
# 
# 返回值:
#   0 - 命令存在
#   1 - 命令不存在
# 
# 行为说明:
#   1. 如果命令存在，函数直接返回 0。
#   2. 如果命令不存在：
#        - 如果 $2 为 true，则显示提示信息并等待用户按回车继续。
#        - 如果 $2 为 false 或未传入，则仅返回 1，不阻塞。
#
# 示例:
#   check_cmd wget          # 检查 wget 是否存在，不显示提示
#   check_cmd curl true     # 检查 curl，如果缺失则显示提示并等待用户操作
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
    local tip="{$2:-false}"

    if [ -z "$cmd" ]; then
        print_error -m "check_cmd: 缺少命令名称参数"
        return 1
    fi

    has_cmd "$cmd" && return 0

    if [ "$tip" = true ]; then
        print_error -m "未检测到命令: $cmd"
        print_info -m   "请先安装该依赖后再继续"
        print_wait_enter
    fi
    return 1
}

# ------------------------------------------------------------------------------
# 函数名: check_docker
# 功能:   检查 Docker 是否就绪
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 已安装
#   1 - 未安装
#
# 示例:
#   check_docker
# ------------------------------------------------------------------------------

check_docker() {
    has_cmd "docker" && return 0

    return 1
}

# ------------------------------------------------------------------------------
# 函数名: check_docker_compose
# 功能:   检查 Docker Compose 是否就绪 (同时支持新版插件模式和旧版独立模式)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 已安装
#   1 - 未安装
#
# 示例:
#   check_docker_compose
# ------------------------------------------------------------------------------
check_docker_compose() {
    docker compose version >/dev/null 2>&1 || has_cmd "docker-compose" && return 0

    return 1
}