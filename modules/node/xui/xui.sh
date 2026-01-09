#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - x-ui 面板安装与管理逻辑
# @文件路径: /modules/node/xui/xui.sh
# @职责:
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-09
# @修改日期: 2025-01-09
#
# @项目源地址: https://github.com/mhsanaei/3x-ui
# @许可证: MIT
# ============================================================

install_x_ui() {
    ui clear

    ui_info "正在准备安装伊朗版 3X-UI 面板一键脚本..."
    
	exec bash <(curl -Ls https://raw.githubusercontent.com/oliver556/x-ui/main/install.sh)
}