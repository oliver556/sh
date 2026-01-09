#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 系统工具模块入口
# @名称:         system/menu.sh
# @职责:
# 1. 显示「系统工具」子菜单
# 2. 接收用户输入
# 3. 分发到系统工具具体功能
# 4. 支持返回主菜单
#
# 设计原则:
# - 模块自闭环（进入 → 操作 → 返回）
# - 不直接处理主菜单
# - 不退出整个程序
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-01
# @修改日期:     2025-01-05
#
# @许可证:       MIT
# ============================================================

# ------------------------------
# 引入依赖模块
# ------------------------------

# 引入 系统信息展示
source "${BASE_DIR}/modules/system/system/system_status.sh"

# ------------------------------
# 系统工具模块主入口
# ------------------------------

system_menu() {
  # 使用无限循环保证模块不会意外退出
  while true; do

    ui clear
    
    ui print page_header_full "⚙️$(ui_spaces)系统工具"

    ui line
    ui_menu_item 1 0 1 "$(ui_spaces 1)系统信息查询"
    ui_menu_item 1 6 2 "${BOLD_GREY}系统更新${RESET}"
    ui_menu_item 1 14 3 "${BOLD_GREY}系统清理 ▶${RESET}"
    ui_menu_done

    ui line
    ui_menu_item 2 0 4 "${BOLD_GREY}$(ui_spaces 1)修改登录密码${RESET}"
    ui_menu_item 2 6 5 "${BOLD_GREY}开启ROOT密码登录${RESET}"
    ui_menu_item 2 6 6 "${BOLD_GREY}开放所有端口${RESET}"

    ui_menu_item 3 0 7 "${BOLD_GREY}$(ui_spaces 1)修改SSH端口${RESET}"
    ui_menu_item 3 7 8 "${BOLD_GREY}优化DNS地址${RESET}"
    ui_menu_item 3 11 9 "${BOLD_GREY}禁用ROOT账户创建新账户${RESET}"
    ui_menu_done

    ui line
    ui_menu_item 9 0 99 "一键重装系统 ▶"
    ui_menu_done

    ui_go_level

    # 读取用户输入
    choice=$(ui_read_choice)

    # 根据用户输入执行不同操作
    case "$choice" in

      1)
        # 选项 1: 查看系统信息
        status_show_all
      ;;

      99)
        # 重装系统
        source "${BASE_DIR}/modules/system/reinstall/menu.sh"
        reinstall_menu
      ;;

      0)
        # 选项 0: 返回主菜单
        return
        # 使用 return 而不是 exit，返回到上级调用者（router）
      ;;

      *)
        # 处理非法输入
        ui_warn_menu "无效选项，请重新输入..."
        # 短暂暂停，避免立刻刷新
        sleep 1
      ;;
    esac
  done
}
