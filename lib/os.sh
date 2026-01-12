#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统信息与发行版识别
#
# @文件路径: lib/os.sh
# @功能描述: 提供获取宿主机系统信息内容
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-31
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: get_os_id
# 功能:   获取系统 ID（获取型）
# 
# 参数: 无
# 
# 返回值:
#   - debian
#   - ubuntu
#   - centos
#   - alpine
# 
# 示例:
#   get_os_id
# ------------------------------------------------------------------------------
get_os_id() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^ID=/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: get_os_version
# 功能:   获取系统版本号
# 
# 参数:
#   无
# 
# 返回值:
#   系统版本字符串，例如 "11"、"20.04"、"8"、"3.18"
# 
# 示例:
#   get_os_version
# ------------------------------------------------------------------------------
get_os_version() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^VERSION_ID/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        uname -r
    fi
}

# ------------------------------------------------------------------------------
# 函数名: get_os_like
# 功能:   获取系统家族（like）
# 
# 参数:
#   无
# 
# 返回值:
#   系统家族，例如 "debian"、"rhel"、"alpine"
# 
# 示例:
#   get_os_like
# ------------------------------------------------------------------------------
get_os_like() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^ID_LIKE/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: get_os_pretty_name
# 功能:   获取系统完整名称（可读，带版本）
# 
# 参数:
#   无
# 
# 返回值:
#   系统完整名称，例如 "Ubuntu 20.04.6 LTS" 或 "Debian GNU/Linux 11"
# 示例:
#   get_os_pretty_name
# ------------------------------------------------------------------------------
get_os_pretty_name() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^PRETTY_NAME/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        uname -s
    fi
}

# ------------------------------------------------------------------------------
# 函数名: os_is
# 功能:   判断当前系统是否为指定 ID（特定发行版）
# 
# 参数:
#   $1 (string): 系统 ID，例如 "debian"、"ubuntu"
# 
# 返回值:
#    0 - 当前系统是指定 ID
#   !0 - 否
#
# 示例:
#   os_is
# ------------------------------------------------------------------------------
os_is() {
    local target="$1"
    [[ "$(get_os_id)" == "$target" ]]
}

# ------------------------------------------------------------------------------
# 函数名: is_debian
# 功能:   是否 Debian（判断型）
# 
# 参数: 无
# 
# 返回值:
#    0 - Debian
#   !0 - 非 Debian
# 
# 示例:
#   is_debian
# ------------------------------------------------------------------------------
is_debian() {
    [ "$(get_os_id)" = "debian" ]
}

# ------------------------------------------------------------------------------
# 函数名: get_is_debian_likeos_id
# 功能:   是否 Debian 系列（判断型，兼容 Ubuntu 等）
# 
# 参数: 无
# 
# 返回值:
#    0 - Debian 系列
#   !0 - 非 Debian 系列
# 
# 示例:
#   is_debian_like
# ------------------------------------------------------------------------------
is_debian_like() {
    get_os_like | grep -qw debian
}

# ******************************************************************************
# 可选拓展：判断常用系统类型
# ******************************************************************************
is_ubuntu() {
    [ "$(get_os_id)" = "ubuntu" ]
}

is_rhel() {
    [ "$(get_os_like)" = "rhel" ]
}

is_alpine() {
    [ "$(get_os_id)" = "alpine" ]
}

# ------------------------------------------------------------------------------
# 函数名: get_os_type
# 功能:   高级拓展：统一检测 Linux 发行版类型
# 
# 参数:
#   无
# 
# 返回值:
#   debian      (适用于 Debian / Ubuntu)
#   rhel        (适用于 RHEL / CentOS / Fedora)
#   alpine      (Alpine Linux)
#   unsupported (其他系统)
# 
# 示例:
#   get_os_type
# ------------------------------------------------------------------------------
get_os_type() {
    local id
    local like
    id=$(get_os_id)
    like=$(get_os_like)

    case "$id" in
        debian|ubuntu)
            echo "debian"
            ;;
        centos|rhel|fedora)
            echo "rhel"
            ;;
        alpine)
            echo "alpine"
            ;;
        *)
            case "$like" in
                debian)
                    echo "debian"
                    ;;
                rhel|fedora)
                    echo "rhel"
                    ;;
                *)
                    echo "unsupported"
                    ;;
            esac
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: os_get_pkg_manager
# 功能:   获取当前系统可用的包管理器类型（获取型）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功获取包管理器
#       输出值为以下之一：
#       - apt      (Debian / Ubuntu)
#       - dnf      (RHEL 8+ / Fedora)
#       - yum      (RHEL 7 / CentOS 7)
#       - apk      (Alpine Linux)
#       - pacman   (Arch Linux)
#       - zypper   (openSUSE)
#       - opkg     (OpenWrt / 嵌入式系统)
#   1 - 未检测到支持的包管理器
# 
# 示例:
#   os_get_pkg_manager
# ------------------------------------------------------------------------------
os_get_pkg_manager() {

    # Debian / Ubuntu 系列包管理器
    # 使用 apt 命令作为判断依据
    if command -v apt &>/dev/null; then
        echo "apt"
        return 0
    fi

    # RHEL 8+ / Fedora 默认包管理器
    # dnf 优先级高于 yum
    if command -v dnf &>/dev/null; then
        echo "dnf"
        return 0
    fi

    # RHEL 7 / CentOS 7 传统包管理器
    if command -v yum &>/dev/null; then
        echo "yum"
        return 0
    fi

    # Alpine Linux 包管理器
    if command -v apk &>/dev/null; then
        echo "apk"
        return 0
    fi

    # Arch Linux 包管理器
    if command -v pacman &>/dev/null; then
        echo "pacman"
        return 0
    fi

    # openSUSE 包管理器
    if command -v zypper &>/dev/null; then
        echo "zypper"
        return 0
    fi

    # OpenWrt / 嵌入式系统包管理器
    if command -v opkg &>/dev/null; then
        echo "opkg"
        return 0
    fi

    # 未匹配到任何已知包管理器
    return 1
}

# ------------------------------------------------------------------------------
# 函数名: guard_system_update
# 功能:   检查当前系统是否支持自动更新（是否有可用包管理器）
# 
# 参数: 无
# 
# 返回值:
#   0 - 支持系统更新
#   1 - 不支持系统更新
# 
# 示例:
#   guard_system_update
# ------------------------------------------------------------------------------
guard_system_update() {
    local pkg_manager
    pkg_manager=$(os_get_pkg_manager) || return 1   # 获取失败则返回 1
    [[ -n "$pkg_manager" ]]                         # 有值返回 0，否则 1
}