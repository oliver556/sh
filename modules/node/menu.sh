#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 节点搭建脚本模块入口
# @路径: /modules/node/menu.sh
# @职责: 整个各种节点搭建脚本
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-09
# @修改日期:     2025-01-09
#
# @许可证:       MIT
# ============================================================

source "${BASE_DIR}/modules/node/3xui/3xui.sh"
source "${BASE_DIR}/modules/node/xui/xui.sh"

# ------------------------------------------------------------------------------
# 函数名: node_menu
# 功能:  节点搭建脚本模块导航
# 
# 参数:
#   无
#
# 返回值:
#   无
# 
# 示例:
#   node_menu
# ------------------------------------------------------------------------------
node_menu() {
  while true; do

    print_clear

    ui print page_header "⑆$(ui_spaces 1)节点搭建脚本合集"

    ui line
    ui_menu_item 1 0 1 "$(ui_spaces 1)3X-UI 面板${BOLD_YELLOW}${ICON_STAR}${BOLD_WHITE}"
    ui_menu_item 1 14 2 "X-UI 面板"
    ui_menu_done

    ui_go_level

    choice=$(ui_read_choice)

    case "$choice" in
      1)
        install_3x_ui
      ;;
      2)
        install_x_ui
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
