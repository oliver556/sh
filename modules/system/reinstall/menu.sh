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

        ui print page_header_full "⚙️ 一键重装系统"
        ui echo "${BOLD_RED}注意: 重装系统有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
        ui echo "${GREY}感谢 MollyLau 大佬 和 bin456789 大佬 的脚本支持！${LIGHT_WHITE} "

        ui line
        # --- 操作选单 ---
        ui_menu_item 1 0 1 " Debian 12 ${BOLD_RED}★${LIGHT_WHITE}"
        ui_menu_item 1 14 2 "Debian 11"
        ui_menu_done

        ui line
        ui_menu_item 2 0 11 "Ubuntu 24.04"
        ui_menu_item 2 12 12 "Ubuntu 22.04 ${BOLD_RED}★${LIGHT_WHITE}"
        ui_menu_done

        # 返回主菜单提示
        ui_go_level 0

        # 读取用户输入
        choice=$(ui_read_choice)

        case "$choice" in
            1)
                if reinstall_logic_main "Debian 12"; then
                    ui_wait_enter
                fi
            ;;
            2)
                if reinstall_logic_main "Debian 11"; then
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
