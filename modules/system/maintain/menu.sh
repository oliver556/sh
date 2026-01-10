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

# source "$BASE_DIR/modules/system/maintain/uninstall.sh" # 卸载脚本

# ------------------------------------------------------------------------------
# 函数名: _refresh_local_version
# 功能:   内部工具：实时刷新本地版本显示
# 
# 参数: 无
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
# 函数名: _restart_script
# 功能:   安全地重启脚本
# ------------------------------------------------------------------------------
_restart_script() {
    # 确保入口文件有执行权限
    chmod +x "${BASE_DIR}/v" "${BASE_DIR}/main.sh" 2>/dev/null

    # 显式使用 bash 来 exec，防止因 Shebang 或权限问题导致的闪退
    if [[ -f "${BASE_DIR}/v" ]]; then
        exec bash "${BASE_DIR}/v"
    elif [[ -f "${BASE_DIR}/main.sh" ]]; then
        exec bash "${BASE_DIR}/main.sh"
    else
        # 如果找不到文件，打印错误而不是直接退出进程
        ui_error "重启失败：找不到启动文件 v 或 main.sh"
        ui_error "请尝试手动运行: bash ${BASE_DIR}/v"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: do_update
# 功能:  更新脚本
# 
# 参数: 无
# 
# 返回值:
#   10 - 更新成功，通知主程序重启
# 
# 示例:
#   do_update
# ------------------------------------------------------------------------------
_do_update() {
    ui clear
    ui print info_header "正在检查更新逻辑..."
    ui blank

    local update_script="$BASE_DIR/modules/system/maintain/update.sh"

    if [[ -f "$update_script" ]]; then
        # 执行更新脚本
        bash "$update_script"
        local exit_code=$?
        
        # 捕捉更新脚本的返回码 10
        if [ $exit_code -eq 10 ]; then
            ui blank
            ui echo "${BOLD_GREEN}✅ 更新完成！${RESET}"
            ui echo "${BOLD_CYAN}🔄 已发出重启信号，准备重载主程序...${RESET}"
            sleep 1
            # 返回 10 给上级
            return 10
        fi
    else
        ui error "未找到核心更新引擎 update.sh"
        ui_wait_enter
    fi
    # 已经是最新，正常等待用户回车返回菜单
    ui_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: do_reinstall
# 功能:  强制重新安装脚本
# 
# 参数: 无
# 
# 返回值:
#   10 - 更新成功，通知主程序重启
# 
# 示例:
#   do_reinstall
# ------------------------------------------------------------------------------
_do_force_reinstall() {
    # source "$BASE_DIR/modules/system/maintain/reinstall.sh" # 重装脚本

    ui clear
    ui print info_header "正在强制重新安装并修复环境..."
    ui blank
    
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        ui blank
        ui echo "${BOLD_GREEN}✅ 强制重新安装完成！${RESET}"
        ui echo "${BOLD_CYAN}🔄 已发出重启信号，准备重载主程序...${RESET}"
        sleep 2
        # 关键修改：返回 10 给上级
        return 10
    else
        ui error "强制安装过程中出现异常"
        ui wait_return
    fi

    # ui clear
    # ui print info_header "正在强制重新安装并修复环境..."
    # ui blank

    # ui clear
    # ui print info_header "正在强制重新安装并修复环境..."
    # ui blank

    # # 1. 使用 bash -s -- 传递参数给远程下载的脚本
    # # 2. 传递 --skip-agreement 让 install.sh 识别并跳过确认环节
    # if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
    #     ui blank
    #     ui_success "强制重新安装完成！${RESET}"
    #     ui echo "${BOLD_CYAN}🔄$(ui_spaces)脚本将在 2 秒后原地重启...${RESET}"
    #     sleep 2
    #     # 重新载入主程序
    #     exec v
    # else
    #     ui_error "强制安装过程中出现异常"
    #     ui_wait_enter
    # fi
}

# ------------------------------------------------------------------------------
# 函数名: do_uninstall
# 功能:  单开 shell 进程以达到卸载后完全退出脚本
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   do_uninstall
# ------------------------------------------------------------------------------
_do_uninstall() {
    # TODO 这里有个问题需要修改
    # 如果是正常卸载的话，脚本可以回退结束shell
    # 如果取消卸载，结果也结束了shell
    # exec bash "$BASE_DIR/modules/system/maintain/uninstall.sh"
    ui clear
    local uninstall_script="$BASE_DIR/modules/system/maintain/uninstall.sh"
    
    if [[ -f "$uninstall_script" ]]; then
        # 卸载是终结操作，这里使用 exec 移交控制权是可以的，
        # 因为卸载脚本执行完就是 exit，不需要回主菜单。
        exec bash "$uninstall_script"
    else
        ui error "未找到卸载脚本"
        ui wait_return
    fi
}

# ------------------------------------------------------------------------------
# 函数名: maintain_menu
# 功能:  管理系统更新中心
# 
# 参数: 无
# 
# 返回值: 无
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
        ui_menu_item 1 0 1 "检查更新并自动升级"
        ui_menu_item 2 0 2 "强制重新安装 (修复环境)"
        ui_menu_item 3 0 3 "卸载 VpsScriptKit"
        ui_menu_done

        # 返回主菜单提示
        ui_go_level

        # 读取用户输入
        choice=$(ui_read_choice)

        case "$choice" in
            1)
                _do_update
                [[ $? -eq 10 ]] && return 10
                ;;
            2)
                _do_force_reinstall
                [[ $? -eq 10 ]] && return 10
                ;;
            3)
                _do_uninstall
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
