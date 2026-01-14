#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 内存 / Swap 子菜单
#
# @文件路径: modules/system/memory/menu.sh
# @功能描述: 内存 / Swap 子菜单
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-14
# ==============================================================================

# ******************************************************************************
# 引入依赖模块
# ******************************************************************************
source "${BASE_DIR}/modules/system/memory/swap.sh"
# ------------------------------------------------------------------------------
# 函数名: system_memory_menu
# 功能:   虚拟内存工具模块菜单
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   system_memory_menu
# ------------------------------------------------------------------------------
system_memory_menu() {
    while true; do

        ui clear
        
        ui print page_header_full "🧠 内存 / Swap 管理"

        swap_status

        ui line
        ui_menu_item 1 0 1 "$(ui_spaces 1)分配 1024M ${BOLD_YELLOW}★${LIGHT_WHITE}"
        ui_menu_item 1 6 2 "分配 2048M"
        ui_menu_item 1 12 3 "分配 4096M"
        ui_menu_done

        ui line
        ui_menu_item 2 0 4 "$(ui_spaces 1)自定义大小"
        ui_menu_item 2 8 5 "关闭 Swap (保留文件)"
        ui_menu_item 2 2 6 "删除 Swap (彻底清除)"
        ui_menu_done

        ui_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 1024
                ui_wait_enter
                ;;

            2)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 2048
                ui_wait_enter
                ;;
            3)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 4096
                ui_wait_enter
                ;;
            4)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create_interactive
                ui_wait_enter
                ;;
            5)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_disable
                ui_wait_enter
                ;;
            6)
                ui clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_remove
                ui_wait_enter
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
