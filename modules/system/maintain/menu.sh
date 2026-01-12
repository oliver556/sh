#!/usr/bin/env bash=

# ==============================================================================
# VpsScriptKit - 更新中心界面
# 
# @文件路径: modules/system/maintain/menu.sh
# @功能描述: 脚本子管理菜单中心
# 
# @作者:    Jamison
# @版本:    0.1.0
# @创建日期: 2026-01-06
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: _refresh_local_version
# 功能:   内部工具：实时刷新本地版本显示
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 显示本地版本号
# 
# 示例:
#   _refresh_local_version
# ------------------------------------------------------------------------------
_refresh_local_version() {
    V_LOCAL="Unknown"
    [[ -f "$BASE_DIR/version" ]] && V_LOCAL=$(cat "$BASE_DIR/version" | xargs)
}

# ------------------------------------------------------------------------------
# 函数名: maintain_menu
# 功能:  管理系统更新中心
# 
# 参数:
#   无
#
# 返回值:
#   无
# 
# 示例:
#   maintain_menu
# ------------------------------------------------------------------------------
maintain_menu() {
    while true; do

        # 获取本地最新版本号，确保更新后重启前显示一致
        _refresh_local_version

        ui clear

        ui print page_header_full "🔄$(ui_spaces)VpsScriptKit 系统更新中心"

        # --- 版本状态看板 ---
        ui echo "${LIGHT_CYAN}当前版本:${RESET}  ${LIGHT_CYAN}v${V_LOCAL}${RESET}"
        ui line

        # --- 操作选单 ---
        ui_menu_item 1 0 1 "$(ui_spaces 1)检查并更新"
        ui_menu_item 2 0 2 "$(ui_spaces 1)强制重安装"
        ui_menu_item 3 0 3 "$(ui_spaces 1)卸载本脚本"
        ui_menu_done

        # 返回主菜单提示
        ui_go_level

        # 读取用户输入
        choice=$(ui_read_choice)

        case "$choice" in
            1)
                local update_script="$BASE_DIR/modules/system/maintain/update.sh"
                bash "$update_script"
                [[ $? -eq 10 ]] && return 10
                ;;
            2)
                local reinstall_script="$BASE_DIR/modules/system/maintain/reinstall.sh"
                bash "$reinstall_script"
                [[ $? -eq 10 ]] && return 10
                ;;
            3)
                local script="$BASE_DIR/modules/system/maintain/uninstall.sh"
                if [[ -f "$script" ]]; then
                    bash "$script"
                    # 0: 表示卸载成功，退出主程序
                    # 1: 表示取消，继续循环
                    [[ $? -eq 0 ]] && exit 0
                else
                    ui error "文件丢失: uninstall.sh"
                    sleep 1
                fi
                ;;
            0)
                return
                ;;
            *)
                ui_warn_menu "无效选项，请重新输入..."
                sleep 1
                ;;
        esac
    done
}
