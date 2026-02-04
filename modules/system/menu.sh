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

# shellcheck disable=1091
{
    # 系统信息查询
    source "${BASE_DIR}/modules/system/system/status.sh"

    # 系统更新
    source "${BASE_DIR}/modules/system/system/update.sh"

    # 系统清理
    source "${BASE_DIR}/modules/system/system/clean.sh"

    # 修改登录密码
    source "${BASE_DIR}/modules/system/security/change_password.sh"

    # 高级防火墙管理
    source "${BASE_DIR}/modules/system/firewall/menu.sh"

    # SSH 安全配置
    source "${BASE_DIR}/modules/system/ssh/menu.sh"

    # 优化DNS地址
    source "${BASE_DIR}/modules/system/network/change_dns.sh"

    # 系统时区调整
    source "${BASE_DIR}/modules/system/timezone/timezone.sh"

    # 切换系统更新源
    source "${BASE_DIR}/modules/system/mirror/mirror.sh"

    # 虚拟内存管理
    source "${BASE_DIR}/modules/system/memory/menu.sh"

    # 内核与拥塞控制
    source "${BASE_DIR}/modules/system/kernel/menu.sh"

    # TCP 参数调优
    source "${BASE_DIR}/modules/system/tcp/menu.sh"

    # 修改主机名
    source "${BASE_DIR}/modules/system/network/change_hostname.sh"

    # 切换优先ipv4/ipv6
    source "${BASE_DIR}/modules/system/network/ipv_priority.sh"

    # 命令行美化工具
    source "${BASE_DIR}/modules/system/terminal/terminal_tuning.sh"
    
    # 一条龙系统调优
    source "${BASE_DIR}/modules/system/tuning/system_tune.sh"
    
    # 重装系统
    source "${BASE_DIR}/modules/system/reinstall/menu.sh"
}

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
        # print_menu_item -r 3 -p 0 -s 2 -i 5 -m "${BOLD_GREY}开启ROOT密码登录${NC}"
        # print_menu_item -r 9  -p 0  -i 9  -s 2 -m "${BOLD_GREY}禁用ROOT账户创建新账户${NC}"
        # print_menu_item -r 19 -p 0  -i 20      -m "${BOLD_GREY}SSH防御程序 (fail2ban)${NC}" -I "${ICON_NAV}" -I "${ICON_NAV}" -T 2
        
        print_box_header "${ICON_GEAR}$(print_spaces 1)系统工具 (System Utilities)"

        print_line
        # print_echo "[基础运维]"
        print_menu_item -r 1  -p 0  -i 1  -s 2 -m "系统信息查询" -I star
        print_menu_item -r 1  -p 11 -i 2  -s 2 -m "系统更新 & 维护"
        
        print_menu_item -r 3  -p 0  -i 3  -s 2 -m "系统垃圾清理"
        print_menu_item -r 3  -p 12 -i 4  -s 2 -m "切换系统更新源" -I "${ICON_NAV}" -T 2

        print_menu_item -r 5  -p 0  -i 5  -s 2 -m "系统时区调整" -I "${ICON_NAV}" -T 2
        print_menu_item -r 5  -p 11 -i 6  -s 2 -m "修改主机名" -I "${ICON_NAV}"
        print_menu_item_done

        print_line
        # print_echo "[安全与访问控制]"
        print_menu_item -r 11 -p 0  -i 11      -m "SSH 服务全能管理" -I "${ICON_NAV}" -I "${ICON_NAV}" -T 2
        print_menu_item -r 11 -p 7  -i 12      -m "高级防火墙管理" -I "${ICON_NAV}" -T 2
        print_menu_item -r 13 -p 0  -i 13      -m "${BOLD_GREY}用户账户管理${NC}" -I "${ICON_NAV}" -I "${ICON_NAV}" -T 2
        print_menu_item -r 13 -p 11 -i 14      -m "修改登录密码"
        print_menu_item_done

        print_line
        # print_echo "[网络与内核优化]"
        print_menu_item -r 21 -p 0  -i 21      -m "内核与拥塞控制(BBR)" -I "${ICON_NAV}" -T 2
        print_menu_item -r 21 -p 4  -i 22      -m "虚拟内存管理(SWAP)" -I "${ICON_NAV}" -T 2

        print_menu_item -r 23 -p 0  -i 23      -m "优化DNS地址" -I "${ICON_NAV}" -T 2
        print_menu_item -r 23 -p 12 -i 24      -m "TCP 参数调优" -I "${ICON_NAV}" -T 2

        print_menu_item -r 25 -p 0  -i 25      -m "切换优先ipv4/ipv6" -I "${ICON_NAV}" -I "${ICON_NAV}" -T 2
        # print_menu_item -r 25 -p 6  -i 26      -m "${BOLD_GREY}开放所有端口 (风险)"
        print_menu_item_done

        print_line
        # print_echo "[终端与工具箱]"
        print_menu_item -r 31 -p 0  -i 31      -m "命令行美化工具" "${ICON_NAV}"
        print_menu_item -r 31 -p 8  -i 32      -m "${BOLD_GREY}设置系统回收站${NC}" -I "${ICON_NAV}" -I "${ICON_NAV}" -T 2

        print_menu_item -r 33 -p 0  -i 33      -m "命令收藏夹"
        print_menu_item -r 33 -p 14 -i 34      -m "${BOLD_GREY}命令行历史记录${NC}"


        print_menu_item_done

        print_line
        print_menu_item -r 98 -p 0  -i 98      -m "一条龙系统调优" "${ICON_NAV}" -T 2 -I star
        print_menu_item -r 98 -p 7  -i 99      -m "一键重装系统" "${ICON_NAV}" -T 2 -I star
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            # 系统信息查询
            1)  status_show_all ;;

            # 系统更新 & 维护
            2)  guard_system_update; print_wait_enter ;;

            # 系统垃圾清理
            3)  guard_system_clean; print_wait_enter ;;

            # 切换系统更新源
            4)  mirror_menu ;;   

            # 系统时区调整
            5) timezone_menu ;;

            # 修改主机名
            6) change_hostname ;;

            # SSH 服务全能管理
            11)  ssh_menu ;;

            # 高级防火墙管理
            12)  firewall_menu ;;

            # 用户账户管理
            13) echo '还没做'; print_wait_enter ;;

            # 修改登录密码
            14)  guard_change_password; print_wait_enter ;;

            # 虚拟内存管理(SWAP)
            21) kernel_menu ;;
            
            # 虚拟内存管理(SWAP)
            22) system_memory_menu ;;

            # 优化DNS地址
            23)  guard_change_dns ;;

            # TCP 参数调优
            24) tcp_tuning_menu ;;

            # 切换优先ipv4/ipv6
            25) ipv_priority_menu ;;

            # 命令行美化工具
            31) terminal_tuning_menu ;;

            # 设置系统回收站
            32) echo '还没做'; print_wait_enter ;;

            # 命令收藏夹
            33)
                print_clear
                bash <(curl -l -s https://raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
                terminal_tuning_menu
                ;;
            
            # 命令行历史记录
            34) echo '还没做'; print_wait_enter ;;

            # 一条龙系统调优
            98) system_tune ;;

            # 一键重装系统
            99) reinstall_menu ;;
            0)  return ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
                ;;
        esac
    done
}
