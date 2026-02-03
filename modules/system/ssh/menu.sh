#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - SSH 密钥登录配置 - 入口
#
# @文件路径: modules/system/ssh/menu.sh
# @功能描述: SSH 密钥登录配置 - 子菜单
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-02-02
# ==============================================================================

ssh_menu() {
    # 引入核心库 + 新的配置库
    # shellcheck disable=SC1091
    {
        source "${BASE_DIR}/modules/system/ssh/ssh_core.sh"
        source "${BASE_DIR}/modules/system/ssh/ssh_config.sh"
        source "${BASE_DIR}/modules/system/ssh/ssh_keygen.sh"
        source "${BASE_DIR}/modules/system/ssh/ssh_import.sh"
        source "${BASE_DIR}/modules/system/ssh/ssh_view.sh"
    }
    while true; do
        print_clear

        print_box_header "${ICON_GEAR}$(print_spaces 1)SSH 服务全能管理"
        print_box_header_tip -h "配置公钥登录可极大提高服务器安全性"

        ssh_get_status_view

        # --- 第一部分: 核心开关 ---
        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "开启密钥模式 (禁用密码登录)"
        print_menu_item -r 1 -p 1 -i 2 -s 2 -m "关闭密钥模式 (恢复密码登录)"
        print_menu_item_done

        # --- 第二部分: 导入公钥 ---
        print_line
        print_menu_item -r 3 -p 0 -i 3 -s 2 -m "手动输入已有公钥"
        print_menu_item -r 3 -p 12 -i 4 -s 2 -m "从GitHub导入已有公钥"
        print_menu_item -r 5 -p 0 -i 5 -s 2 -m "从URL导入已有公钥"
        print_menu_item_done

        # --- 第三部分: 高级配置 (这里集成了端口修改) ---
        print_line
        print_menu_item -r 6 -p 0 -i 6 -s 2 -m "修改 SSH 端口 (防爆破)"
        print_menu_item -r 6 -p 6 -i 7 -s 2 -m "开启连接防断开 (KeepAlive)"
        print_menu_item -r 8 -p 0 -i 8 -s 2 -m "生成本地连接配置 (Config)"
        print_menu_item_done

        # --- 第四部分: 查看与审计 ---
        print_line
        print_menu_item -r 11 -p 0 -i 11 -m "查看本机密钥"
        print_menu_item -r 11 -p 16 -i 12 -m "编辑公钥文件"
        print_menu_item -r 13 -p 0 -i 13 -m "查看登录日志 (审计)"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1)  if ssh_enable_auto; then print_wait_enter; fi ;;
            2)  ssh_restore_policy ;;
            3)  if ssh_import_manual; then print_wait_enter; fi ;;
            4)  if ssh_import_github; then print_wait_enter; fi ;;
            5)  if ssh_import_url; then print_wait_enter; fi ;;
            6)  ssh_change_port; print_wait_enter ;;
            7)  ssh_enable_keepalive ;;
            8)  ssh_generate_local_config ;;
            11) ssh_view_keys ;;
            12) ssh_edit_authorized_keys ;;
            13) ssh_audit_logs ;;
            0)  return ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
                ;;
        esac
    done
}