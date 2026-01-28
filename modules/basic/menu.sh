#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 基础工具
#
# @文件路径: modules/basic/menu.sh
# @功能描述: 基础工具 - 导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-13
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
# shellcheck disable=SC1091
source "${BASE_DIR}/lib/package.sh"

# ------------------------------------------------------------------------------
# 函数名: basic_menu
# 功能:   基础工具导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   basic_menu
# ------------------------------------------------------------------------------
basic_menu() {
    while true; do
        print_clear

        print_box_header "${ICON_MAINTAIN}$(print_spaces 1)基础工具 (Basic Utilities)"
        
        print_line
        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "软件安装中心" -I "$ICON_NAV" -T 2
        print_menu_item -r 2 -p 0 -i 2 -s 2 -m "Tmux 管理" -I "$ICON_NAV" -T 2
        print_menu_item_done

        print_menu_go_level

        refresh_hash

        choice=$(read_choice)

        case "$choice" in
            1)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/basic/installer/installer.sh"
                install_menu                
                ;;
            2)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/basic/tmux/tmux.sh"
                tmux_ui_menu
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