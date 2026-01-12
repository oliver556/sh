#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统清理
#
# @文件路径: modules/system/system/clean.sh
# @功能描述: 根据当前系统包管理器，执行系统缓存 / 无用依赖 / 日志清理
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-12
# ==============================================================================

guard_system_clean(){
    ui clear

    if system_clean; then
        ui_success "系统清理完成"
    else
        ui_error "系统清理失败"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: system_clean
# 功能:   执行系统垃圾清理与缓存回收（行为型）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 系统清理成功完成
#   1 - 系统不支持或清理过程中发生错误
# 
# 示例:
#   system_clean
# ------------------------------------------------------------------------------
system_clean() {
    local pkg_manager

    # 获取当前系统使用的包管理器
    pkg_manager="$(os_get_pkg_manager)" || {
        # 未检测到支持的包管理器，直接返回失败
        ui_error "当前系统未检测到支持的包管理器，无法执行系统清理"
        return 1
    }

    ui_info "正在执行系统清理操作..."

    # --------------------------------------------------------------------------
    # 根据包管理器类型执行对应的清理逻辑
    # --------------------------------------------------------------------------
    case "$pkg_manager" in

        # ----------------------------------------------------------------------
        # Debian / Ubuntu 系列
        # ----------------------------------------------------------------------
        apt)
            ui_info "检测到 apt 包管理器，开始清理系统..."

            # 修复 dpkg 中断状态（防止清理失败）
            fix_dpkg

            # 移除无用依赖并清理配置文件
            apt autoremove --purge -y || return 1

            # 清理本地包缓存
            apt clean -y || return 1
            apt autoclean -y || return 1

            # 清理 systemd 日志
            journalctl --rotate
            journalctl --vacuum-time=1s
            journalctl --vacuum-size=500M
            ;;

        # ----------------------------------------------------------------------
        # RHEL / CentOS / Fedora（dnf）
        # ----------------------------------------------------------------------
        dnf)
            ui_info "检测到 dnf 包管理器，开始清理系统..."

            # 重建 rpm 数据库
            rpm --rebuilddb

            # 移除无用依赖
            dnf autoremove -y || return 1

            # 清理缓存并重建缓存索引
            dnf clean all
            dnf makecache

            # 清理 systemd 日志
            journalctl --rotate
            journalctl --vacuum-time=1s
            journalctl --vacuum-size=500M
            ;;

        # ----------------------------------------------------------------------
        # RHEL 7 / CentOS 7（yum）
        # ----------------------------------------------------------------------
        yum)
            ui_info "检测到 yum 包管理器，开始清理系统..."

            # 重建 rpm 数据库
            rpm --rebuilddb

            # 移除无用依赖
            yum autoremove -y || return 1

            # 清理缓存并重建缓存索引
            yum clean all
            yum makecache

            # 清理 systemd 日志
            journalctl --rotate
            journalctl --vacuum-time=1s
            journalctl --vacuum-size=500M
            ;;

        # ----------------------------------------------------------------------
        # Alpine Linux
        # ----------------------------------------------------------------------
        apk)
            ui_info "检测到 apk 包管理器，开始清理系统..."

            # 清理 apk 包缓存
            apk cache clean || return 1

            # 清理系统日志
            rm -rf /var/log/*

            # 清理 apk 缓存目录
            rm -rf /var/cache/apk/*

            # 清理临时文件
            rm -rf /tmp/*
            ;;

        # ----------------------------------------------------------------------
        # Arch Linux
        # ----------------------------------------------------------------------
        pacman)
            ui_info "检测到 pacman 包管理器，开始清理系统..."

            # 移除孤立依赖（如果存在）
            pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || true

            # 清空 pacman 缓存
            pacman -Scc --noconfirm || return 1

            # 清理 systemd 日志
            journalctl --rotate
            journalctl --vacuum-time=1s
            journalctl --vacuum-size=500M
            ;;

        # ----------------------------------------------------------------------
        # openSUSE
        # ----------------------------------------------------------------------
        zypper)
            ui_info "检测到 zypper 包管理器，开始清理系统..."

            # 清理所有缓存
            zypper clean --all || return 1

            # 刷新软件源
            zypper refresh

            # 清理 systemd 日志
            journalctl --rotate
            journalctl --vacuum-time=1s
            journalctl --vacuum-size=500M
            ;;

        # ----------------------------------------------------------------------
        # OpenWrt / 嵌入式系统
        # ----------------------------------------------------------------------
        opkg)
            ui_info "检测到 opkg 包管理器，开始清理系统..."

            # 清理系统日志
            rm -rf /var/log/*

            # 清理临时文件
            rm -rf /tmp/*
            ;;

        # ----------------------------------------------------------------------
        # FreeBSD（pkg）
        # ----------------------------------------------------------------------
        pkg)
            ui_info "检测到 pkg 包管理器，开始清理系统..."

            # 移除无用依赖
            pkg autoremove -y || return 1

            # 清理缓存
            pkg clean -y || return 1

            # 清理系统日志
            rm -rf /var/log/*

            # 清理临时文件
            rm -rf /tmp/*
            ;;

        # ----------------------------------------------------------------------
        # 未支持的包管理器
        # ----------------------------------------------------------------------
        *)
            ui_error "当前包管理器不受支持: $pkg_manager"
            return 1
            ;;
    esac

    return 0
}
