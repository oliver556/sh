#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 包管理工具
#
# @文件路径: lib/utils/package.sh
# @功能描述:
#   提供跨 Linux 发行版的软件包工具函数，自动识别包管理器，
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-13
# ==============================================================================

# ------------------------------------------------------------------------------
# 内部函数: _pkg_exec
# 功能:     根据动作与包名，调用对应包管理器执行
#
# 参数:
#   $1 - 动作类型 (install | remove | update | clean)
#   $@ - 包名列表（update / clean 时可为空）
#
# 返回值:
#   0 - 成功
#   1 - 失败 / 不支持的包管理器 / 参数错误
#
# 说明:
#   ⚠ 内部函数，不应被业务脚本直接调用
# ------------------------------------------------------------------------------
_pkg_exec() {
    local action="$1"
    shift

    if [[ -z "$action" ]]; then
        print_error "未指定包管理动作"
        return 1
    fi

    # --------------------------------------------------------------------------
    # Debian / Ubuntu / 基于 Debian 的发行版
    # 使用 apt 包管理器
    # --------------------------------------------------------------------------
    if command -v apt &>/dev/null; then
        case "$action" in
            install)
                apt update -y
                apt install -y "$@"
                ;;
            remove)
                apt purge -y "$@"
                ;;
            update)
                apt update -y
                ;;
            clean)
                apt autoremove -y
                apt clean
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # Fedora / RHEL 8+ / CentOS 8+ 使用 dnf
    # --------------------------------------------------------------------------
    elif command -v dnf &>/dev/null; then
        case "$action" in
            install)
                dnf install -y "$@" ;;
            remove)
                dnf remove -y "$@"
                ;;
            update)
                dnf makecache
                ;;
            clean)
                dnf autoremove -y
                dnf clean all
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # CentOS 7 / RHEL 7 / 老版本 Fedora 使用 yum
    # --------------------------------------------------------------------------
    elif command -v yum &>/dev/null; then
        case "$action" in
            install)
                yum -y update
                yum install -y epel-release
                yum install -y "$@"
                ;;
            remove)
                yum remove -y "$@"
                ;;
            update)
                yum -y update
                ;;
            clean)
                yum autoremove -y
                yum clean all
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # Alpine Linux 使用 apk
    # --------------------------------------------------------------------------
    elif command -v apk &>/dev/null; then
        case "$action" in
            install)
                apk update
                apk add "$@"
                ;;
            remove)
                apk del "$@"
                ;;
            update)
                apk update
                ;;
            clean)
                rm -rf /var/cache/apk/*
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # Arch Linux / Manjaro 使用 pacman
    # --------------------------------------------------------------------------
    elif command -v pacman &>/dev/null; then
        case "$action" in
            install)
                pacman -Syu --noconfirm
                pacman -S --noconfirm "$@"
                ;;
            remove)
                pacman -Rns --noconfirm "$@"
                ;;
            update)
                pacman -Sy
                ;;
            clean)
                pacman -Sc --noconfirm
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # openSUSE / SLE 使用 zypper
    # --------------------------------------------------------------------------
    elif command -v zypper &>/dev/null; then
        case "$action" in
            install)
                zypper refresh
                zypper install -y "$@"
                ;;
            remove)
                zypper remove -y "$@"
                ;;
            update)
                zypper refresh
                zypper update -y
                ;;
            clean)
                zypper clean
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # 嵌入式 Linux / 路由器使用 opkg
    # --------------------------------------------------------------------------
    elif command -v opkg &>/dev/null; then
        case "$action" in
            install)
                opkg update
                opkg install "$@"
                ;;
            remove)
                opkg remove "$@"
                ;;
            update)
                opkg update
                ;;
            clean)
                opkg clean
                ;;
            *)
                return 1
                ;;
        esac

    # --------------------------------------------------------------------------
    # FreeBSD / BSD 系统使用 pkg
    # 非 Linux，但 VPS 场景偶尔存在
    # --------------------------------------------------------------------------
    elif command -v pkg &>/dev/null; then
        case "$action" in
            install)
                pkg update
                pkg install -y "$@"
                ;;
            remove)
                pkg delete -y "$@"
                ;;
            update)
                pkg update
                ;;
            clean)
                pkg clean
                ;;
            *)
                return 1
                ;;
        esac

    else
        print_error -m "未识别的包管理器"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 对外函数: pkg_install
# 功能:     安装软件包（已存在则跳过）
# ------------------------------------------------------------------------------
pkg_install() {
    [[ $# -eq 0 ]] && { print_error -m "请输入包名"; return 1; }

    local pkg
    for pkg in "$@"; do
        if ! command -v "$pkg" &>/dev/null; then
            print_step -m "正在安装 $pkg ..."
            _pkg_exec install "$pkg" || return 1
        else
            print_info "$pkg 已存在，跳过"
        fi
    done
}

# ------------------------------------------------------------------------------
# 对外函数: pkg_remove
# 功能:     卸载软件包
# ------------------------------------------------------------------------------
pkg_remove() {
    [[ $# -eq 0 ]] && { print_error -m "未提供包名"; return 1; }
    print_step -m "正在卸载软件包: $*"
    _pkg_exec remove "$@"
}

# ------------------------------------------------------------------------------
# 对外函数: pkg_update
# 功能:     更新软件源索引
# ------------------------------------------------------------------------------
pkg_update() {
    print_step -m "正在更新软件源..."
    _pkg_exec update
}

# ------------------------------------------------------------------------------
# 对外函数: pkg_clean
# 功能:     清理无用依赖和缓存
# ------------------------------------------------------------------------------
pkg_clean() {
    print_step -m "正在清理系统包缓存..."
    _pkg_exec clean
}