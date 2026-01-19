#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统信息工具
#
# @文件路径: lib/system.sh
# @功能描述: 提供获取宿主机系统信息内容
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-31
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: sys_get_hostname
# 功能:   获取主机名
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 主机名
#   失败 - N/A
# 
# 示例:
#   sys_get_hostname
# ------------------------------------------------------------------------------
sys_get_hostname() {
    # hostname 命令获取系统主机名
    hostname 2>/dev/null || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_kernel
# 功能:   获取内核版本
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 内核版本
#   失败 - N/A
# 
# 示例:
#   sys_get_kernel
# ------------------------------------------------------------------------------
sys_get_kernel() {
    # uname -r 返回内核版本
    uname -r 2>/dev/null || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_arch
# 功能:   获取系统CPU架构
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统架构
#   失败 - N/A
# 
# 示例:
#   sys_get_arch
# ------------------------------------------------------------------------------
sys_get_arch() {
    # uname -m 返回系统架构
    uname -m 2>/dev/null || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_uptime
# 功能:   获取系获取运行时间（uptime）CPU架构
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 运行时间
#   失败 - N/A
# 
# 示例:
#   sys_get_uptime
# ------------------------------------------------------------------------------
sys_get_uptime() {
    # 优先从 /proc/uptime 获取原始秒数
    if [[ -f /proc/uptime ]]; then
        local uptime_sec
        uptime_sec=$(cut -d. -f1 /proc/uptime)

        # 计算天、时、分
        local days=$((uptime_sec / 86400))
        local hours=$((uptime_sec % 86400 / 3600))
        local mins=$((uptime_sec % 3600 / 60))

        local result=""
        # 仅当大于 0 天时显示天
        [[ $days -gt 0 ]] && result="${days}天 "
        # 如果有天数，即使小时为 0 也显示，或者小时大于 0 时显示
        [[ $hours -gt 0 || $days -gt 0 ]] && result="${result}${hours}时 "
        # 始终显示分钟
        result="${result}${mins}分"

        echo "$result"
    else
        # 备选方案：如果 /proc/uptime 不存在，则回退到 uptime 命令并简单清理
        uptime -p | sed -e 's/up //' -e 's/ days\?,/天/' -e 's/ hours\?,/时/' -e 's/ minutes\?/分/'
    fi
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_cpu_model
# 功能:   获取 CPU 型号
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - CPU 型号
#   失败 - N/A
# 
# 示例:
#   sys_get_cpu_model
# ------------------------------------------------------------------------------
sys_get_cpu_model() {
    # 解析 /proc/cpuinfo 获取 CPU 型号
    awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//' || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_cpu_cores
# 功能:   获取 CPU 核心数
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - CPU 核心数
#   失败 - N/A
# 
# 示例:
#   sys_get_cpu_cores
# ------------------------------------------------------------------------------
sys_get_cpu_cores() {
    # 使用 nproc 获取逻辑核心数
    nproc 2>/dev/null || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_cpu_mhz
# 功能:   获取 CPU 主频 (MHz)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - CPU 主频 (MHz)
#   失败 - N/A
# 
# 示例:
#   sys_get_cpu_mhz
# ------------------------------------------------------------------------------
sys_get_cpu_mhz() {
    local mhz
    # 从 /proc/cpuinfo 提取频率数值
    mhz=$(awk -F: '/cpu MHz/ {print $2; exit}' /proc/cpuinfo | xargs 2>/dev/null)

    if [[ -n "$mhz" ]]; then
        # 转换为 GHz 并保留一位小数
        echo "$mhz" | awk '{printf "%.1f GHz\n", $1/1000}'
    else
        # 备选方案：通过 lscpu 获取（部分虚拟化环境 /proc/cpuinfo 不显示频率）
        local lscpu_mhz
        lscpu_mhz=$(lscpu 2>/dev/null | grep "CPU MHz" | awk '{print $NF}')
        if [[ -n "$lscpu_mhz" ]]; then
            echo "$lscpu_mhz" | awk '{printf "%.1f GHz\n", $1/1000}'
        else
            echo "N/A"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_cpu_usage
# 功能:   获取 CPU 使用率
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - CPU 使用率
#   失败 - N/A
# 
# 示例:
#   sys_get_cpu_usage
# ------------------------------------------------------------------------------
sys_get_cpu_usage() {
    # 读取两次快照，计算差值
    # 字段: cpu  user nice system idle iowait irq softirq steal guest guest_nice
    
    read_cpu_stat() {
        grep 'cpu ' /proc/stat
    }

    local stat1=($(read_cpu_stat))
    sleep 0.5
    local stat2=($(read_cpu_stat))

    if [[ -z "${stat1[*]}" || -z "${stat2[*]}" ]]; then
        echo "N/A"
        return
    fi

    # 计算总时间: sum($2..$11)
    local total1=0
    local total2=0
    for i in {1..10}; do
        total1=$((total1 + stat1[i]))
        total2=$((total2 + stat2[i]))
    done

    # 计算空闲时间: idle($5) + iowait($6)
    local idle1=$((stat1[4] + stat1[5]))
    local idle2=$((stat2[4] + stat2[5]))

    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))

    if [[ $total_diff -gt 0 ]]; then
        # 使用 awk 进行浮点运算
        # 如果计算结果的小数部分为 0，则按整数格式化输出；否则保留一位小数
        awk "BEGIN {
            usage = 100 * ($total_diff - $idle_diff) / $total_diff;
            if (usage == int(usage)) {
                printf \"%d%%\", usage
            } else {
                printf \"%.1f%%\", usage
            }
        }"
    else
        echo "0%"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_load_avg
# 功能:   获取系统负载
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统负载
#   失败 - N/A
# 
# 示例:
#   sys_get_load_avg
# ------------------------------------------------------------------------------
sys_get_load_avg() {
    # /proc/loadavg 前三个字段即为 1, 5, 15 分钟负载
    awk '{printf "%s, %s, %s\n", $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "N/A"
}

# # ------------------------------------------------------------------------------
# # 函数名: sys_get_mem_usage
# # 功能:   获取物理内存使用
# # 
# # 参数:
# #   无
# # 
# # 返回值:
# #   成功 - 物理内存使用
# #   失败 - N/A
# # 
# # 示例:
# #   sys_get_mem_usage
# # ------------------------------------------------------------------------------
# sys_get_mem_usage() {
#     # free -m 获取内存总量和已用量
#     local total used
#     read -r total used <<< $(free -m | awk '/Mem:/ {print $2, $3}')
#     if [[ -n "$total" && -n "$used" ]]; then
#         local percent
#         # 避免除以 0
#         if [[ "$total" -le 0 ]]; then
#             echo "0M/0M (0%)"
#         else
#             percent=$(( used * 100 / total ))
#             echo "${used}M/${total}M (${percent}%)"
#         fi
#     else
#         echo "N/A"
#     fi
# }

# # ------------------------------------------------------------------------------
# # 函数名: sys_get_swap_usage
# # 功能:   获取虚拟使用
# # 
# # 参数:
# #   无
# # 
# # 返回值:
# #   成功 - 虚拟使用
# #   失败 - N/A
# # 
# # 示例:
# #   sys_get_swap_usage
# # ------------------------------------------------------------------------------
# sys_get_swap_usage() {
#     # free -m 获取 swap 使用
#     local total used
#     read -r total used <<< $(free -m | awk '/Swap:/ {print $2, $3}')
#     if [[ -n "$total" && -n "$used" ]]; then
#         local percent
#         if [[ "$total" -eq 0 ]]; then
#             percent=0
#         else
#             percent=$(( used * 100 / total ))
#         fi
#         echo "${used}M/${total}M (${percent}%)"
#     else
#         echo "N/A"
#     fi
# }

# ------------------------------------------------------------------------------
# 函数名: sys_get_disk_usage
# 功能:   获取磁盘使用情况
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 磁盘使用情况
#   失败 - N/A
# 
# 示例:
#   sys_get_disk_usage
# ------------------------------------------------------------------------------
sys_get_disk_usage() {
    # df -h 获取根分区的使用情况
    # $3: 已用, $2: 总量, $5: 百分比
    local disk_info
    disk_info=$(df -h / | awk 'NR==2 {print $3, $2, $5}')
    
    if [[ -n "$disk_info" ]]; then
        read -r used total percent <<< "$disk_info"
        echo "${used}/${total} (${percent})"
    else
        echo "N/A"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_datetime
# 功能:   获取系统当前时间
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统当前时间
#   失败 - N/A
# 
# 示例:
#   sys_get_datetime
# ------------------------------------------------------------------------------
sys_get_datetime() {
    # 获取系统当前时间 (格式: 2026-01-05 12:25 PM)
    date "+%Y-%m-%d %I:%M %p"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_timezone
# 功能:   获取系统当前时区
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统当前时区
#   失败 - N/A
# 
# 示例:
#   sys_get_timezone
# ------------------------------------------------------------------------------
sys_get_timezone() {
    local tz
    # 尝试从 /etc/timezone 或 /etc/localtime 软链接获取 IANA 时区名称
    tz=$(cat /etc/timezone 2>/dev/null || readlink /etc/localtime | sed 's#.*/zoneinfo/##')
    echo "${tz:-N/A}"
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_tcp_congestion
# 功能:   获取系统负载算法 (TCP拥塞控制)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统负载算法 (TCP拥塞控制)
#   失败 - N/A
# 
# 示例:
#   sys_get_tcp_congestion
# ------------------------------------------------------------------------------
sys_get_tcp_congestion() {
    # 读取 /proc/sys/net/ipv4/tcp_congestion_control
    cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: get_supported_package_manager
# 功能:   判断是否支持主流 Linux 包管理器 (apt / yum / dnf)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 系统负载算法 (TCP拥塞控制)
#   失败 - N/A
#
# apt → Debian / Ubuntu
# yum → CentOS / RHEL 7
# yum → CentOS / RHEL 7 
#
# 示例:
#    pm=$(get_supported_package_manager) || print_error -m "不支持的系统"
# ------------------------------------------------------------------------------
get_supported_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    else
        return 1
    fi
}

