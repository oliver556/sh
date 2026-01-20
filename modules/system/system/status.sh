#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统状态展示模块
#
# @文件路径: modules/system/system/status.sh
# @功能描述: 展示相关信息
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-03
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************
# shellcheck disable=SC1091
source "${BASE_DIR}/lib/guards/memory.sh"

# ------------------------------------------------------------------------------
# 函数名: status_show_system_info
# 功能:   展示系统概览信息 (系统身份与状态)
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_system_info
# ------------------------------------------------------------------------------
status_show_system_info() {
    print_clear
    print_box_info -m "${ICON_GEAR}$(print_spaces 1)系统信息查询"
    print_line -c "-"
    print_key_value -k "主机名" -v "$_sys_get_hostname"
    print_key_value -k "系统版本" -v "$_get_os_pretty_name"
    print_key_value -k "Linux版本" -v "$_sys_get_kernel"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_cpu_info
# 功能:   展示 CPU 信息 (处理器性能)
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_cpu_info
# ------------------------------------------------------------------------------
status_show_cpu_info() {
    print_key_value -k "CPU架构" -v "$_sys_get_arch"
    print_key_value -k "CPU型号" -v "$_sys_get_cpu_model"
    print_key_value -k "CPU核心数" -v "$_sys_get_cpu_cores"
    print_key_value -k "CPU频率" -v "$_sys_get_cpu_mhz"
    print_key_value -k "CPU占用" -v "$_sys_get_cpu_usage"
    print_key_value -k "系统负载" -v "$_sys_get_load_avg"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_memory_info
# 功能:   展示内存信息 (存储与资源)
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_memory_info
# ------------------------------------------------------------------------------
status_show_memory_info() {
    print_key_value -k "物理内存" -v "$_sys_get_mem_usage"
    print_key_value -k "虚拟内存" -v "$_sys_get_swap_usage"
    print_key_value -k "硬盘占用" -v "$_sys_get_disk_usage"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_network_info
# 功能:   展示网络信息 (网络标识)
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_network_info
# ------------------------------------------------------------------------------
status_show_network_info() {
    print_key_value -k "运营商" -v "$_net_get_isp"
    print_key_value -k "IPv4公网" -v "$_net_get_ipv4"
    print_key_value -k "IPv6公网" -v "$_net_get_ipv6"
    print_key_value -k "DNS服务器" -v "$_net_get_dns"

    # print_key_value -k "IPv4内网" -v "$_net_get_private_ipv4"
    # print_key_value -k "IPv6内网" -v "$_net_get_private_ipv6"
    # print_key_value -k "默认网关" -v "$_net_get_gateway"
    # print_key_value -k "网络连通性" -v "$_check_net_connectivity"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_transmission_info
# 功能:   展示系统运行时间 传输统计
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_transmission_info
# ------------------------------------------------------------------------------
status_show_transmission_info() {
    print_key_value -k "总接收" -v "$_net_get_total_rx"
    print_key_value -k "总发送" -v "$_net_get_total_tx"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_algo_info
# 功能:   展示系统网络优化
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_algo_info
# ------------------------------------------------------------------------------
status_show_algo_info() {
    print_key_value -k "网络算法" -v "$_net_get_algo"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_tz_time_info
# 功能:   展示系统地理位置与系统时间
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_tz_time_info
# ------------------------------------------------------------------------------
status_show_tz_time_info() {
    print_key_value -k "地理位置" -v "$_net_get_geo"
    print_key_value -k "系统时间" -v "$_sys_get_tz_time"
    print_line -c "-"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_run_time_info
# 功能:   展示系统运行时间
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_run_time_info
# ------------------------------------------------------------------------------
status_show_run_time_info() {
    print_key_value -k "运行时间" -v "$_sys_get_uptime"
}

# ------------------------------------------------------------------------------
# 函数名: _get_sys_info
# 功能:   统一获取需要的信息
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   _get_sys_info
# ------------------------------------------------------------------------------
_get_sys_info() {
    _sys_get_hostname=$(sys_get_hostname)
    _get_os_pretty_name=$(get_os_pretty_name)
    _sys_get_kernel=$(sys_get_kernel)
    _sys_get_uptime=$(sys_get_uptime)
    _sys_get_tz_time="$(sys_get_timezone) $(sys_get_datetime)"
    _net_get_geo=$(net_get_geo)

    _sys_get_arch=$(sys_get_arch)
    _sys_get_cpu_model=$(sys_get_cpu_model)
    _sys_get_cpu_cores=$(sys_get_cpu_cores)
    _sys_get_cpu_mhz=$(sys_get_cpu_mhz)
    _sys_get_cpu_usage=$(sys_get_cpu_usage)
    _sys_get_load_avg=$(sys_get_load_avg)

    _sys_get_mem_usage=$(sys_get_mem_usage)
    _sys_get_swap_usage=$(sys_get_swap_usage)
    _sys_get_disk_usage=$(sys_get_disk_usage)

    _net_get_isp=$(net_get_isp)
    # _net_get_ipv4=$(net_get_ipv4)
    # _net_get_ipv6=$(net_get_ipv6)
    _net_get_ipv4=$(get_public_ip 4)
    _net_get_ipv6=$(get_public_ip 6)
    # _net_get_private_ipv4=$(net_get_private_ipv4)
    # _net_get_private_ipv6=$(net_get_private_ipv6)
    # _net_get_dns=$(net_get_dns | tr '\n' ', ' | sed 's/, $//')
    _net_get_dns=$(net_get_dns | xargs | sed 's/ /, /g')
    # _net_get_gateway=$(net_get_gateway)
    # _check_net_connectivity=$(check_net_connectivity)

    _net_get_total_rx=$(net_get_total_rx)
    _net_get_total_tx=$(net_get_total_tx)
    _net_get_algo="$(net_get_congestion_control) $(net_get_qdisc)"
}

# ------------------------------------------------------------------------------
# 函数名: status_show_all
# 功能:   展示完整状态信息
# 
# 参数:
#   无
# 
# 返回值:
#   相关信息输出
# 
# 示例:
#   status_show_all
# ------------------------------------------------------------------------------
status_show_all() {
    print_clear

    print_echo "${BLUE}正在查询中，请稍后...${BOLD_WHITE}"

    _get_sys_info

    print_clear

    status_show_system_info
    status_show_cpu_info
    status_show_memory_info
    status_show_network_info
    status_show_transmission_info
    status_show_algo_info
    status_show_tz_time_info
    status_show_run_time_info

    print_wait_enter
}
