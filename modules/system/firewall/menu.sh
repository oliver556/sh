#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - 高级防火墙管理 - 入口
#
# @文件路径: modules/system/firewall/menu.sh
# @功能描述: 高级防火墙管理子菜单
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-23
# ==============================================================================

# ******************************************************************************
# 引入依赖模块
# ******************************************************************************

# ------------------------------------------------------------------------------
# 函数名: firewall_menu
# 功能:   高级防火墙管理模块菜单
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   firewall_menu
# ------------------------------------------------------------------------------
firewall_menu() {
    while true; do

        print_clear
        
        print_box_header "${ICON_GEAR}$(print_spaces 1)高级防火墙管理 (Firewall Manager)"
        print_line
        print_menu_item -r 1 -p 0 -s 2 -i 1 -m "开放指定端口"
        print_menu_item -r 1 -p 12 -i 2 -m "关闭指定端口"
        print_menu_item_done
        print_menu_item -r 2 -p 0 -s 2 -i 3 -m "开放所有端口"
        print_menu_item -r 2 -p 12 -i 4 -m "重置防火墙规则"
        print_menu_item_done
        print_menu_item -r 3 -p 0 -s 2 -i 5 -m "查看当前开放端口"
        print_menu_item_done

        print_line
        print_menu_item -r 4 -p 0 -s 2 -i 6 -m "${BOLD_GREY}IP白名单${NC}"
        print_menu_item -r 4 -p 16 -i 7 -m "${BOLD_GREY}IP黑名单${NC}"
        print_menu_item_done
        print_menu_item -r 5 -p 0 -s 2 -i 8 -m "${BOLD_GREY}清除指定IP${NC}"
        print_menu_item_done

        print_line
        print_menu_item -r 6 -p 0 -i 11 -m "允许PING"
        print_menu_item -r 6 -p 15 -i 12 -m "禁止PING"
        print_menu_item_done

        print_line
        print_menu_item -r 11 -p 0 -i 13 -m "${BOLD_GREY}启动DDOS防御${NC}"
        print_menu_item -r 11 -p 11 -i 14 -m "${BOLD_GREY}关闭DDOS防御${NC}"
        print_menu_item_done

        print_line
        print_menu_item -r 12 -p 0 -i 15 -m "[黑名单] 屏蔽指定国家"
        print_menu_item -r 12 -p 2 -i 16 -m "[白名单] 仅许指定国家"
        print_menu_item_done
        print_menu_item -r 13 -p 0 -i 17 -m "[黑名单] 解封指定国家"
        print_menu_item -r 13 -p 2 -i 18 -m "[全  局] 清空所有规则"
        print_menu_item_done
        print_menu_item -r 14 -p 0 -i 19 -m "[全  局] 查看规则状态"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1|2|3|4|5)
                # 1-5 号菜单，加载端口管理脚本
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/port.sh"
                
                case "$choice" in
                    1) firewall_start_open_port ; print_wait_enter;;
                    2) firewall_start_close_port ; print_wait_enter;;
                    3) firewall_start_open_all ; print_wait_enter;;
                    4) firewall_start_reset ; print_wait_enter;;
                    5) firewall_start_list ; print_wait_enter;;
                esac
                ;;

            6)
                # shellcheck disable=SC1091
                # source "${BASE_DIR}/modules/system/security/change_password.sh"
                print_wait_enter
                ;;
            7)
                # shellcheck disable=SC1091
                # source "${BASE_DIR}/modules/system/network/change_ssh_port.sh"
                # guard_change_ssh_port
                print_wait_enter
                ;;
            8)
                # shellcheck disable=SC1091
                # source "${BASE_DIR}/modules/system/network/change_dns.sh"
                # guard_change_dns
                print_wait_enter
                ;;
            11|12)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/port.sh"
                    if [[ "$choice" == "11" ]]; then
                        if firewall_start_enable_ping; then print_wait_enter; fi
                    else
                        if firewall_start_disable_ping; then print_wait_enter; fi
                    fi
                    ;;
            13)
                print_wait_enter
                ;;
            14)
                print_wait_enter
                ;;
            15|16|17|18|19)
                # 国家 IP 管理 (GeoIP)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/geoip.sh"
                
                case "$choice" in
                    15)
                        if firewall_start_block_country; then print_wait_enter; fi
                        ;;
                    16)
                        if firewall_start_allow_country; then print_wait_enter; fi
                        ;;
                    17)
                        if firewall_start_unblock_specific_country; then print_wait_enter; fi
                        ;;
                    18)
                        if firewall_start_unblock_country; then print_wait_enter; fi
                        ;;
                    19)
                        firewall_start_list_country_rules
                        print_wait_enter
                        ;;
                esac
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
