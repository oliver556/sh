#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 内存 / Swap 状态辅助显示模块
#
# @文件路径: lib/guards/memory.sh
# @功能描述: 提供物理内存和虚拟内存 (Swap) 的可视化输出函数
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-14
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************
source "${BASE_DIR}/lib/system_mem.sh"

# ------------------------------------------------------------------------------
# 函数名: sys_get_mem_usage
# 功能:   获取物理内存使用情况格式化字符串
# 参数:   无
# 返回值: 成功 - "已用M/总量M (百分比%)"；失败 - "N/A"
# 示例:   sys_get_mem_usage
# ------------------------------------------------------------------------------
sys_get_mem_usage() {
    local total used
    total=$(mem_get_total_mb)
    used=$(mem_get_used_mb)

    if [[ -n "$total" && -n "$used" ]]; then
        local percent
        # 避免除以 0
        if [[ "$total" -le 0 ]]; then
            echo "0M/0M (0%)"
        else
            percent=$(( used * 100 / total ))
            echo "${used}M/${total}M (${percent}%)"
        fi
    else
        echo "N/A"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: sys_get_swap_usage
# 功能:   获取虚拟内存(Swap)使用情况格式化字符串
# 参数:   无
# 返回值: 成功 - "已用M/总量M (百分比%)"；失败 - "N/A"
# 示例:   sys_get_swap_usage
# ------------------------------------------------------------------------------
sys_get_swap_usage() {
    local total used
    total=$(swap_get_total_mb)
    used=$(swap_get_used_mb)

    if [[ -n "$total" && -n "$used" ]]; then
        local percent
        if [[ "$total" -eq 0 ]]; then
            percent=0
        else
            percent=$(( used * 100 / total ))
        fi
        echo "${used}M/${total}M (${percent}%)"
    else
        echo "N/A"
    fi
}