#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - DockTer Agent (自动检测 Linux / Unraid / OpenWrt) 模块
# 
# @文件路径: modules/advanced/dockter_agent/dockter_agent.sh
# @功能描述: 负责 DockTer Agent 一键安装
# @项目地址: https://github.com/shenxianmq/Dockter-Agent
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-15
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: install_dockter_agent
# 功能:   执行 DockTer Agent 自动检测 官方安装脚本
#
# 参数:
#   无
#
# 返回值:
#   无
#
# 示例:
#   install_dockter_agent
# ------------------------------------------------------------------------------
install_dockter_agent() {
    print_clear

    ui_box_info "开始安装 DockTer Agent (自动检测 Linux / Unraid / OpenWrt) 一键脚本..."

    local region
    region=$(net_region)

    if [ "$region" = "Global" ]; then
        log_info "网络环境检测: 国际互联 (Global)"
    else
        log_info "网络环境检测: 中国大陆 (CN)"
    fi

    sleep 2

    if [ "$region" = "CN" ]; then
        exec bash <(curl -fsSL "https://github.viplee.cc/https://raw.githubusercontent.com/shenxianmq/Dockter-Agent/main/install-dockter-agent.sh")
    else
        exec bash <(curl -fsSL "https://raw.githubusercontent.com/shenxianmq/Dockter-Agent/main/install-dockter-agent.sh")
    fi
    
}