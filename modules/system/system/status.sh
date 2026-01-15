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
    ui clear
    ui print info_header "⚙$(ui_spaces 1)系统信息查询"
    ui line_2
    ui item_list "主机名" 15 "$_sys_get_hostname"
    ui item_list "系统版本" 15 "$_get_os_pretty_name"
    ui item_list "Linux版本" 15 "$_sys_get_kernel"
    ui line_2
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
    ui item_list "CPU架构" 15 "$_sys_get_arch"
    ui item_list "CPU型号" 15 "$_sys_get_cpu_model"
    ui item_list "CPU核心数" 15 "$_sys_get_cpu_cores"
    ui item_list "CPU频率" 15 "$_sys_get_cpu_mhz"
    ui item_list "CPU占用" 15 "$_sys_get_cpu_usage"
    ui item_list "系统负载" 15 "$_sys_get_load_avg"
    ui line_2
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
    ui item_list "物理内存" 15 "$_sys_get_mem_usage"
    ui item_list "虚拟内存" 15 "$_sys_get_swap_usage"
    ui item_list "硬盘占用" 15 "$_sys_get_disk_usage"
    ui line_2
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
    ui item_list "运营商" 15 "$_net_get_isp"
    ui item_list "IPv4公网" 15 "$_net_get_ipv4"
    # ui item_list "IPv4 内网" 15 "$_net_get_private_ipv4"
    ui item_list "IPv6公网" 15 "$_net_get_ipv6"
    # ui item_list "IPv6 内网" 15 "$_net_get_private_ipv6"
    ui item_list "DNS服务器" 15 "$_net_get_dns"
    # ui item_list "默认网关" 15 "$_net_get_gateway"
    # ui item_list "网络连通性" 15 "$_check_net_connectivity"
    ui line_2
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
    ui item_list "总接收" 15 "$_net_get_total_rx"
    ui item_list "总发送" 15 "$_net_get_total_tx"
    ui line_2
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
    ui item_list "网络算法" 15 "$_net_get_algo"
    ui line_2
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
    ui item_list "地理位置" 15 "$_net_get_geo"
    ui item_list "系统时间" 15 "$_sys_get_tz_time"
    ui line_2
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
    ui item_list "运行时间" 15 "$_sys_get_uptime"
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
    _net_get_ipv4=$(net_get_ipv4)
    # _net_get_private_ipv4=$(net_get_private_ipv4)
    _net_get_ipv6=$(net_get_ipv6)
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
    ui clear

    ui echo "${BLUE}正在查询中，请稍后...${LIGHT_WHITE}"

    _get_sys_info

    ui clear

    status_show_system_info
    status_show_cpu_info
    status_show_memory_info
    status_show_network_info
    status_show_transmission_info
    status_show_algo_info
    status_show_tz_time_info
    status_show_run_time_info

    ui_wait_enter
}
