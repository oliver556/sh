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
        print_clear
        print_box_header "${ICON_MAINTAIN}$(print_spaces 1)进阶工具 (Power Utilities)"
      
        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(print_spaces 1)DockTer Agent " -I star
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1)
                print_clear
                source "${BASE_DIR}/modules/advanced/dockter_agent/menu.sh"
                dockter_agent_menu
                ;;
            0)
                return
            ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}