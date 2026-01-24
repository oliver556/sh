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

        # --- 第一组：端口基础 ---
        print_line
        print_menu_item -r 1 -p 0 -s 2 -i 1 -m "开放指定端口"
        print_menu_item -r 1 -p 12 -i 2 -m "关闭指定端口"
        print_menu_item_done
        print_menu_item -r 2 -p 0 -s 2 -i 3 -m "开放所有端口"
        print_menu_item -r 2 -p 12 -i 4 -m "重置防火墙规则"
        print_menu_item_done
        print_menu_item -r 3 -p 0 -s 2 -i 5 -m "查看当前开放端口"
        print_menu_item_done

        # --- 第二组：Ping ---
        print_line
        print_menu_item -r 7 -p 0 -s 2 -i 6 -m "允许PING"
        print_menu_item -r 7 -p 16 -i 7 -m "禁止PING"
        print_menu_item_done

        # --- 第三组：DDoS ---
        print_line
        print_menu_item -r 11 -p 0 -s 2 -i 8 -m "启动DDOS防御"
        print_menu_item -r 11 -p 12 -i 9 -m "关闭DDOS防御"
        print_menu_item_done

        # --- 第四组：指定 IP (11-15) ---
        print_line
        print_menu_item -r 4 -p 0 -i 11 -m "[黑名单] 封禁指定IP"
        print_menu_item -r 4 -p 4 -i 12 -m "[白名单] 放行指定IP"
        print_menu_item_done
        print_menu_item -r 5 -p 0 -i 13 -m "[全  局] 解封指定IP"
        print_menu_item -r 5 -p 4 -i 14 -m "[全  局] 清空所有IP"
        print_menu_item_done
        print_menu_item -r 6 -p 0 -i 15 -m "[全  局] 查看IP名单"
        print_menu_item_done

        # --- 第五组：国家/GeoIP (21-25) ---
        print_line
        print_menu_item -r 12 -p 0 -i 21 -m "[黑名单] 屏蔽指定国家"
        print_menu_item -r 12 -p 2 -i 22 -m "[白名单] 仅许指定国家"
        print_menu_item_done
        print_menu_item -r 13 -p 0 -i 23 -m "[黑名单] 解封指定国家"
        print_menu_item -r 13 -p 2 -i 24 -m "[全  局] 清空所有规则"
        print_menu_item_done
        print_menu_item -r 14 -p 0 -i 25 -m "[全  局] 查看规则状态"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            # 1-9: 基础功能 (Port, Ping, DDoS) -> port.sh
            1|2|3|4|5|6|7|8|9)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/port.sh"
                
                case "$choice" in
                    1) firewall_start_open_port ; print_wait_enter;;
                    2) firewall_start_close_port ; print_wait_enter;;
                    3) firewall_start_open_all ; print_wait_enter;;
                    4) firewall_start_reset ; print_wait_enter;;
                    5) firewall_start_list ; print_wait_enter;;
                    6) firewall_start_enable_ping; print_wait_enter ;;
                    7) if firewall_start_disable_ping; then print_wait_enter; fi ;;
                    8) if firewall_start_enable_ddos; then print_wait_enter; fi ;;
                    9) if firewall_start_disable_ddos; then print_wait_enter; fi ;;
                esac
                ;;

            # 11-15: 指定 IP 管理 -> ip.sh
            11|12|13|14|15)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/ip.sh"
                
                case "$choice" in
                    11) if firewall_start_deny_ip; then print_wait_enter; fi ;;
                    12) if firewall_start_allow_ip ; then print_wait_enter; fi ;;
                    13) if firewall_start_remove_ip; then print_wait_enter; fi ;;
                    14) if firewall_start_flush_ips; then print_wait_enter; fi ;;
                    15) firewall_start_list_ips; print_wait_enter ;;
                esac
                ;;

            # 21-25: 国家 GeoIP 管理 -> geoip.sh
            21|22|23|24|25)
                # 国家 IP 管理 (GeoIP)
                # shellcheck disable=SC1091
                source "${BASE_DIR}/modules/system/firewall/geoip.sh"
                
                case "$choice" in
                    21)
                        if firewall_start_block_country; then print_wait_enter; fi
                        ;;
                    22)
                        if firewall_start_allow_country; then print_wait_enter; fi
                        ;;
                    23)
                        if firewall_start_unblock_specific_country; then print_wait_enter; fi
                        ;;
                    24)
                        if firewall_start_unblock_country; then print_wait_enter; fi
                        ;;
                    25)
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
