#!/usr/bin/env bash

### ============================================================
# VpsScriptKit - 系统信息与发行版识别 - 函数库
# @名称:         os.sh
# @职责:
# - 提供获取宿主机系统信息内容
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2025-12-31
# @修改日期:     2025-01-04
#
# @许可证:       MIT
### ============================================================


# -------------------------------
# Linux 系统发行版识别
# -------------------------------

# 获取系统发行版名字（带版本）
os_get_pretty_name() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^PRETTY_NAME/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        uname -s
    fi
}

# 获取系统 ID（Ubuntu/Debian/CentOS 等）
os_get_id() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^ID=/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        echo "unknown"
    fi
}

# 获取系统版本号（数字）
os_get_version() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^VERSION_ID/ {gsub(/"/,"",$2); print $2}' /etc/os-release
    else
        uname -r
    fi
}

# -------------------------------
# 工具函数
# -------------------------------

# 判断当前系统是否为特定发行版
os_is() {
    local target="$1"
    [[ "$(os_get_id)" == "$target" ]]
}
