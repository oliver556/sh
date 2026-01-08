#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 重装系统
# @名称:         /modules/system/reinstall/menu.sh
# @职责:
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-07
# @修改日期:     2025-01-07
#
# @许可证:       MIT
# ============================================================

# ------------------------------
# 引入依赖模块
# ------------------------------

source "${BASE_DIR}/modules/system/reinstall/reinstall.sh"

# ------------------------------
# 维护模块入口函数
# ------------------------------
reinstall_menu() {
    while true; do
        ui clear

        ui print page_header_full "⚙️$(ui_spaces)一键重装系统"
        ui echo "${BOLD_RED}注意: 重装系统有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
        ui echo "${GREY}感谢 Leitbogioro 大佬 和 Bin456789 大佬 的脚本支持！"
        ui line
        ui echo "${GREY}Leitbogioro 项目地址: https://github.com/leitbogioro/Tools"
        ui echo "${GREY}Bin456789   项目地址: https://github.com/bin456789/reinstall${LIGHT_WHITE} "

        ui line
        # --- 操作选单 ---
        ui_menu_item 1 0 1 " Debian 13"
        ui_menu_item 1 16 2 "Debian 12 ${BOLD_RED}★${LIGHT_WHITE}"
        ui_menu_done
        ui_menu_item 1 0 3 " Debian 11"
        ui_menu_item 1 16 4 "Debian 10"
        ui_menu_done

        ui line
        ui_menu_item 2 0 11 "Ubuntu 24.04"
        ui_menu_item 2 12 12 "Ubuntu 22.04 ${BOLD_RED}★${LIGHT_WHITE}"
        ui_menu_done
        ui_menu_item 2 0 13 "Ubuntu 20.04"
        ui_menu_item 2 12 14 "Ubuntu 18.04"
        ui_menu_done

        ui line
        ui_menu_item 3 0 21 "CentOS 10"
        ui_menu_item 3 15 22 "CentOS 9"
        ui_menu_done

        ui line
        ui_menu_item 4 0 31 "Alpine Linux"
        ui_menu_done

        ui line
        ui_menu_item 5 0 41 "Windows 11"
        ui_menu_item 5 14 42 "Windows 10"
        ui_menu_done
        ui_menu_item 5 0 43 "Windows 7"
        ui_menu_item 5 15 44 "Windows Server 2025"
        ui_menu_done
        ui_menu_item 5 0 45 "Windows Server 2022"
        ui_menu_item 5 5 46 "Windows Server 2019"
        ui_menu_done

        # 返回主菜单提示
        ui_go_level

        # 读取用户输入
        choice=$(ui_read_choice)

        case "$choice" in
            1)
                if reinstall_logic_main "Debian 13"; then
                    ui_wait_enter
                fi
            ;;
            2)
                if reinstall_logic_main "Debian 12"; then
                    ui_wait_enter
                fi
            ;;
            3)
                if reinstall_logic_main "Debian 11"; then
                    ui_wait_enter
                fi
            ;;
            4)
                if reinstall_logic_main "Debian 10"; then
                    ui_wait_enter
                fi
            ;;
            11)
                if reinstall_logic_main "Ubuntu 24.04"; then
                    ui_wait_enter
                fi
            ;;
            12)
                if reinstall_logic_main "Ubuntu 22.04"; then
                    ui_wait_enter
                fi
            ;;
            13)
                if reinstall_logic_main "Ubuntu 20.04"; then
                    ui_wait_enter
                fi
            ;;
            14)
                if reinstall_logic_main "Ubuntu 18.04"; then
                    ui_wait_enter
                fi
            ;;
            21)
                if reinstall_logic_main "CentOS 10"; then
                    ui_wait_enter
                fi
            ;;
            22)
                if reinstall_logic_main "CentOS 9"; then
                    ui_wait_enter
                fi
            ;;
            31)
                if reinstall_logic_main "Alpine Linux"; then
                    ui_wait_enter
                fi
            ;;
            41)
                if reinstall_logic_main "Windows 11"; then
                    ui_wait_enter
                fi
            ;;
            42)
                if reinstall_logic_main "Windows 10"; then
                    ui_wait_enter
                fi
            ;;
            43)
                if reinstall_logic_main "Windows 7"; then
                    ui_wait_enter
                fi
            ;;
            44)
                if reinstall_logic_main "Windows Server 2025"; then
                    ui_wait_enter
                fi
            ;;
            45)
                if reinstall_logic_main "Windows Server 2022"; then
                    ui_wait_enter
                fi
            ;;
            46)
                if reinstall_logic_main "Windows Server 2019"; then
                    ui_wait_enter
                fi
            ;;
            0)
                # 返回上级（由 router 自动处理）
                return
            ;;
            *)
                ui_error "无效选项，请重新输入"
                sleep 1
            ;;
        esac
    done
}
