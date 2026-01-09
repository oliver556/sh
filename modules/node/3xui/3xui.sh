#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 3x-ui 面板安装与管理逻辑
# @文件路径: /modules/node/3xui/3xui.sh
# @职责:
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-09
# @修改日期: 2025-01-09
#
# @项目源地址: https://github.com/mhsanaei/3x-ui
# @许可证: MIT
# ============================================================

install_3x_ui() {
    ui clear

    ui_info "正在准备安装伊朗版 3X-UI 面板一键脚本..."
    
	exec bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
}