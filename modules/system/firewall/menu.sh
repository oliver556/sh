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
            print_menu_item -r 4 -p 0 -s 2 -i 6 -m "IP白名单"
            print_menu_item -r 4 -p 16 -i 7 -m "IP黑名单"
            print_menu_item_done
            print_menu_item -r 5 -p 0 -s 2 -i 8 -m "清除指定IP"
            print_menu_item_done

            print_line
            print_menu_item -r 6 -p 0 -i 11 -m "允许PING"
            print_menu_item -r 6 -p 15 -i 12 -m "禁止PING"
            print_menu_item_done

            print_line
            print_menu_item -r 11 -p 0 -i 13 -m "启动DDOS防御"
            print_menu_item -r 11 -p 11 -i 14 -m "关闭DDOS防御"
            print_menu_item_done

            print_line
            print_menu_item -r 12 -p 0 -i 15 -m "阻止指定国家IP"
            print_menu_item -r 12 -p 9 -i 16 -m "仅允许指定国家IP"
            print_menu_item_done
            print_menu_item -r 13 -p 0 -i 17 -m "解除指定国家IP限制"
            print_menu_item_done

            print_menu_go_level

            choice=$(read_choice)

            case "$choice" in

                1)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/utils.sh"
                    firewall_start_open_port
                    print_wait_enter
                    ;;

                2)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/utils.sh"
                    firewall_start_close_port
                    print_wait_enter
                    ;;
                3)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/utils.sh"
                    firewall_start_open_all
                    print_wait_enter
                    ;;
                4)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/utils.sh"
                    firewall_start_reset
                    print_wait_enter
                    ;;
                5)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/firewall/utils.sh"
                    firewall_start_list
                    print_wait_enter
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
                11)
                    # shellcheck disable=SC1091
                    source "${BASE_DIR}/modules/system/memory/menu.sh"
                    system_memory_menu
                    ;;
                12)
                    print_wait_enter
                    ;;
                13)
                    print_wait_enter
                    ;;
                14)
                    print_wait_enter
                    ;;
                15)
                    print_wait_enter
                    ;;
                16)
                    print_wait_enter
                    ;;
                17)
                    print_wait_enter
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
