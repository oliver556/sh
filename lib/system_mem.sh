#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统内存获取模块
#
# @文件路径: lib/system_mem.sh
# @功能描述: 提供物理内存和虚拟内存 (Swap) 的基础获取函数
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-14
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: mem_get_total_mb
# 功能:   获取物理内存总量 (MB)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 总内存数值 (整数 MB)
#   失败 - 0
# 
# 示例:
#   total=$(mem_get_total_mb)
# ------------------------------------------------------------------------------
mem_get_total_mb() {
    local total
    total=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null)
    echo "${total:-0}"
}

# ------------------------------------------------------------------------------
# 函数名: mem_get_used_mb
# 功能:   获取已使用物理内存 (MB)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 已用内存数值 (整数 MB)
#   失败 - 0
# 
# 示例:
#   used=$(mem_get_used_mb)
# ------------------------------------------------------------------------------
mem_get_used_mb() {
    local total avail used
    # 优先使用 MemAvailable (现代内核 3.14+)，它考虑了可回收的 cache
    avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null)
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null)
    
    if [[ -n "$total" && -n "$avail" ]]; then
        used=$(( (total - avail) / 1024 ))
        echo "${used}"
    else
        # 老版本内核降级方案: total - free - buffers - cached
        local free buffers cached
        free=$(awk '/MemFree/ {print $2}' /proc/meminfo 2>/dev/null)
        buffers=$(awk '/Buffers/ {print $2}' /proc/meminfo 2>/dev/null)
        cached=$(awk '/^Cached/ {print $2}' /proc/meminfo 2>/dev/null)
        used=$(( (total - free - buffers - cached) / 1024 ))
        echo "${used:-0}"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: swap_get_total_mb
# 功能:   获取虚拟内存总量 (Swap, MB)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 总 Swap 数值 (整数 MB)
#   失败 - 0
# 
# 示例:
#   swap_total=$(swap_get_total_mb)
# ------------------------------------------------------------------------------
swap_get_total_mb() {
    local total
    total=$(awk '/SwapTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null)
    echo "${total:-0}"
}

# ------------------------------------------------------------------------------
# 函数名: swap_get_used_mb
# 功能:   获取已使用虚拟内存 (Swap, MB)
# 
# 参数:
#   无
# 
# 返回值:
#   成功 - 已用 Swap 数值 (整数 MB)
#   失败 - 0
# 
# 示例:
#   swap_used=$(swap_get_used_mb)
# ------------------------------------------------------------------------------
swap_get_used_mb() {
    local total free used
    total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo 2>/dev/null)
    free=$(awk '/SwapFree/ {print $2}' /proc/meminfo 2>/dev/null)
    
    if [[ -n "$total" && -n "$free" ]]; then
        used=$(( (total - free) / 1024 ))
        echo "${used}"
    else
        echo "0"
    fi
}
