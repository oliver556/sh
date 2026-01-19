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
source "${BASE_DIR}/lib/system_mem.sh"

# ------------------------------------------------------------------------------
# 函数名: _swap_get_suggested_size
# 功能:   示例：在创建 Swap 前展示给用户看
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   _swap_get_suggested_size
# ------------------------------------------------------------------------------
_swap_get_suggested_size(){
    local total_ram=$(mem_get_total_mb)
    local suggest_info=$(swap_get_suggested_info)

    ui_text "物理内存: ${total_ram}M"
    ui_text "推荐 Swap: ${suggest_info}"
}

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

        print_clear
        
        print_box_info --msg "${ICON_SWAP}$(ui_spaces 1)内存 / Swap 管理"

        swap_status

        # _swap_get_suggested_size

        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(ui_spaces 1)分配 1024M" -I star
        print_menu_item -r 1 -p 6 -i 2 -m "分配 2048M"
        print_menu_item -r 1 -p 12 -i 3 -m "分配 4096M"
        print_menu_item_done

        print_line
        print_menu_item -r 2 -p 0 -i 4 -m "$(ui_spaces 1)自定义大小"
        print_menu_item -r 2 -p 8 -i 5 -m "关闭 Swap (保留文件)"
        print_menu_item -r 2 -p 2 -i 6 -m "删除 Swap (彻底清除)"
        print_menu_item_done

        print_menu_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 1024
                print_wait_enter
                ;;

            2)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 2048
                print_wait_enter
                ;;
            3)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create 4096
                print_wait_enter
                ;;
            4)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_create_interactive
                print_wait_enter
                ;;
            5)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                if swap_disable; then
                    print_wait_enter
                fi
                ;;
            6)
                print_clear
                source "${BASE_DIR}/modules/system/memory/swap.sh"
                swap_remove
                print_wait_enter
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
