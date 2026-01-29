#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统工具模块 - 入口
#
# @文件路径: modules/system/menu.sh
# @功能描述: 系统工具 - 子菜单
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-01
# ==============================================================================

# ******************************************************************************
# 引入依赖模块
# ******************************************************************************
# source "${BASE_DIR}/modules/system/system/status.sh"
# source "${BASE_DIR}/modules/system/system/update.sh"
# source "${BASE_DIR}/modules/system/system/clean.sh"

# ------------------------------------------------------------------------------
# 函数名: system_menu
# 功能:   系统工具模块菜单
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   system_menu
# ------------------------------------------------------------------------------
system_menu() {
    while true; do

        print_clear
        
        print_box_header "${ICON_GEAR}$(print_spaces 1)系统工具 (System Utilities)"
        print_line
        print_menu_item -r 1 -p 0 -s 2 -i 1 -m "系统信息查询" -I star
        print_menu_item -r 1 -p 12 -i 2 -m "系统更新"
        print_menu_item -r 2 -p 0 -s 2 -i 3 -m "系统清理"
        print_menu_item -r 2 -p 17 -i 4 -m "修改登录密码"
        # print_menu_item_done

        # print_line
        print_menu_item -r 3 -p 0 -s 2 -i 5 -m "${BOLD_GREY}开启ROOT密码登录${NC}"
        print_menu_item -r 3 -p 9 -i 6 -m "高级防火墙管理" -I "${ICON_NAV}" -T 2

        print_menu_item -r 7 -p 0 -s 2 -i 7 -m "修改SSH端口"
        print_menu_item -r 7 -p 14 -i 8 -m "优化DNS地址" -I "${ICON_NAV}" -T 2
        print_menu_item -r 9 -p 0 -s 2 -i 9 -m "${BOLD_GREY}禁用ROOT账户创建新账户${NC}"
        print_menu_item -r 9 -p 2 -i 10 -m "系统时区调整" -I "${ICON_NAV}" -T 2
        print_menu_item_done
        
        print_line
        print_menu_item -r 10 -p 0 -i 11 -m "切换系统更新源" -I "${ICON_NAV}" -T 2
        print_menu_item -r 10 -p 9 -i 12 -m "虚拟内存管理" -I "${ICON_NAV}" -T 2
        print_menu_item -r 13 -p 0 -i 13 -m "内核与拥塞控制" -I "${ICON_NAV}" -T 2
        print_menu_item -r 13 -p 9 -i 14 -m "TCP 参数调优" -I "${ICON_NAV}" -T 2
        print_menu_item_done

        print_line
        print_menu_item -r 31 -p 0 -i 31 -m "命令行美化工具" "${ICON_NAV}" -T 2 -I star
        print_menu_item -r 31 -p 7 -i 32 -m "命令收藏夹" -T 2 -I star
        
        print_menu_item_done

        print_line
        print_menu_item -r 98 -p 0 -i 98 -m "一条龙系统调优" "${ICON_NAV}" -T 2 -I star
        print_menu_item -r 99 -p 0 -i 99 -m "一键重装系统" "${ICON_NAV}" -T 2 -I star
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in

            1)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/system/status.sh"
                status_show_all
                ;;

            2)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/system/update.sh"
                guard_system_update
                print_wait_enter
                ;;
            3)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/system/clean.sh"
                guard_system_clean
                print_wait_enter
                ;;
            4)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/security/change_password.sh"
                guard_change_password
                print_wait_enter
                ;;
            6)  
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/menu.sh"
                firewall_menu
                # print_wait_enter

                ;;
            7)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/network/change_ssh_port.sh"
                change_ssh_port
                print_wait_enter
                ;;
            8)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/network/change_dns.sh"
                guard_change_dns
                ;;
            10)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/timezone/timezone.sh"
                timezone_menu
                ;;
            11)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/mirror/mirror.sh"
                mirror_menu
                ;;    
            12)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/memory/menu.sh"
                system_memory_menu
                ;;
            13)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/kernel/menu.sh"
                kernel_menu
                ;;
            14)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/tcp/menu.sh"
                tcp_tuning_menu
                ;;
            31)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/terminal/terminal_tuning.sh"
                terminal_tuning_menu
                ;;
            32)
                print_clear
                bash <(curl -l -s https://raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
                terminal_tuning_menu
                ;;
            98)
                print_clear
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/tuning/system_tune.sh"
                system_tune
                # print_wait_enter
                ;;
            99)
                # 重装系统
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/reinstall/menu.sh"
                reinstall_menu
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
