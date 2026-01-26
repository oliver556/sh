#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 重装系统
#
# @文件路径: modules/system/reinstall/menu.sh
# @功能描述: 提供重装系统导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-07
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
source "${BASE_DIR}/modules/system/reinstall/reinstall.sh"

# ------------------------------------------------------------------------------
# 函数名: reinstall_menu
# 功能:   重装系统导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   reinstall_menu
# ------------------------------------------------------------------------------
reinstall_menu() {
    while true; do
        print_clear

        print_box_header "${ICON_GEAR}$(print_spaces 1)一键重装系统 (OS Reinstallation)"
        print_error "注意: 重装系统有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
        print_echo "${GRAY}感谢 Leitbogioro 大佬 和 Bin456789 大佬 的脚本支持！"
        print_line
        print_echo "${GRAY}Leitbogioro 项目地址: https://github.com/leitbogioro/Tools"
        print_echo "${GRAY}Bin456789   项目地址: https://github.com/bin456789/reinstall${BOLD_WHITE} "

        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(print_spaces 1)Debian 13"
        print_menu_item -r 1 -p 16 -i 2 -m "Debian 12" -I star
        print_menu_item -r 2 -p 0 -i 3 -m "$(print_spaces 1)Debian 11"
        print_menu_item -r 2 -p 16 -i 4 -m "Debian 10"
        print_menu_item_done

        print_line
        print_menu_item -r 3 -p 0 -i 11 -m "Ubuntu 24.04"
        print_menu_item -r 3 -p 12 -i 12 -m "Ubuntu 22.04" -I star
        print_menu_item_done
        print_menu_item -r 4 -p 0 -i 13 -m "Ubuntu 20.04"
        print_menu_item -r 4 -p 12 -i 14 -m "Ubuntu 18.04"
        print_menu_item_done

        print_line
        print_menu_item -r 5 -p 0 -i 21 -m "CentOS 10"
        print_menu_item -r 5 -p 15 -i 22 -m "CentOS 9"
        print_menu_item_done

        print_line
        print_menu_item -r 6 -p 0 -i 31 -m "Alpine Linux"
        print_menu_item_done

        print_line
        print_menu_item -r 7 -p 0 -i 41 -m "Windows 11"
        print_menu_item -r 7 -p 14 -i 42 -m "Windows 10"
        print_menu_item_done
        print_menu_item -r 8 -p 0 -i 43 -m "Windows 7"
        print_menu_item -r 8 -p 15 -i 44 -m "Windows Server 2025"
        print_menu_item_done
        print_menu_item -r 9 -p 0 -i 45 -m "Windows Server 2022"
        print_menu_item -r 9 -p 5 -i 46 -m "Windows Server 2019"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1)
                if reinstall_logic_main "Debian 13"; then
                    print_wait_enter
                fi
            ;;
            2)
                if reinstall_logic_main "Debian 12"; then
                    print_wait_enter
                fi
            ;;
            3)
                if reinstall_logic_main "Debian 11"; then
                    print_wait_enter
                fi
            ;;
            4)
                if reinstall_logic_main "Debian 10"; then
                    print_wait_enter
                fi
            ;;
            11)
                if reinstall_logic_main "Ubuntu 24.04"; then
                    print_wait_enter
                fi
            ;;
            12)
                if reinstall_logic_main "Ubuntu 22.04"; then
                    print_wait_enter
                fi
            ;;
            13)
                if reinstall_logic_main "Ubuntu 20.04"; then
                    print_wait_enter
                fi
            ;;
            14)
                if reinstall_logic_main "Ubuntu 18.04"; then
                    print_wait_enter
                fi
            ;;
            21)
                if reinstall_logic_main "CentOS 10"; then
                    print_wait_enter
                fi
            ;;
            22)
                if reinstall_logic_main "CentOS 9"; then
                    print_wait_enter
                fi
            ;;
            31)
                if reinstall_logic_main "Alpine Linux"; then
                    print_wait_enter
                fi
            ;;
            41)
                if reinstall_logic_main "Windows 11"; then
                    print_wait_enter
                fi
            ;;
            42)
                if reinstall_logic_main "Windows 10"; then
                    print_wait_enter
                fi
            ;;
            43)
                if reinstall_logic_main "Windows 7"; then
                    print_wait_enter
                fi
            ;;
            44)
                if reinstall_logic_main "Windows Server 2025"; then
                    print_wait_enter
                fi
            ;;
            45)
                if reinstall_logic_main "Windows Server 2022"; then
                    print_wait_enter
                fi
            ;;
            46)
                if reinstall_logic_main "Windows Server 2019"; then
                    print_wait_enter
                fi
            ;;
            0)
                # 返回上级（由 router 自动处理）
                return
            ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}
