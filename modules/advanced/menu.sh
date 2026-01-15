#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 进阶工具
#
# @文件路径: modules/advanced/menu.sh
# @功能描述: 进阶工具导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-15
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
# source "${BASE_DIR}/modules/advanced/dockter_agent/menu.sh"

# ------------------------------------------------------------------------------
# 函数名: advanced_menu
# 功能:   进阶工具导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   advanced_menu
# ------------------------------------------------------------------------------
advanced_menu() {
  while true; do
        ui clear

        ui print page_header_full "⚒$(ui_spaces 1)进阶工具"
      
        ui line
        # --- 操作选单 ---
        ui_menu_item 1 0 1 "$(ui_spaces 1)DockTer Agent ${BOLD_YELLOW}★${LIGHT_WHITE}"
        ui_menu_done

        ui_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                ui clear
                source "${BASE_DIR}/modules/advanced/dockter_agent/menu.sh"
                dockter_agent_menu
                # ui_wait_enter
                ;;
            0)
                return
            ;;
            *)
                ui_warn_menu "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}