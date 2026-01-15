#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - DockTer Agent 标准 Linux 模块
# 
# @文件路径: modules/advanced/dockter_agent/install_dockter_agent_binary.sh
# @功能描述: 负责 DockTer Agent 一键安装
# @项目地址: https://github.com/shenxianmq/Dockter-Agent
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-15
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: install_dockter_agent_binary
# 功能:   执行 DockTer Agent Linux 官方安装脚本
#
# 参数:
#   无
#
# 返回值:
#   无
#
# 示例:
#   install_dockter_agent_binary
# ------------------------------------------------------------------------------
install_dockter_agent_binary() {
    ui clear

    ui_box_info "开始安装 DockTer Agent Linux 一键脚本..."
    sleep 1
    return 0
    # exec bash <(curl -fsSL "bash <(curl -fsSL "https://raw.githubusercontent.com/shenxianmq/Dockter-Agent/main/install-dockter-agent-binary.sh")")
}