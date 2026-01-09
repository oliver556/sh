#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 更新中心界面
# @名称:         system/vsk_script/menu.sh
# @职责: 处理维护任务，并响应卸载脚本发出的退出信号
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-06
# @修改日期:     2025-01-06
#
# @许可证:       MIT
# ============================================================

# ------------------------------
# 基础配置
# ------------------------------
INSTALL_DIR="/opt/VpsScriptKit"

# ------------------------------
# 内部工具：实时刷新本地版本显示
# ------------------------------
_refresh_local_version() {
    V_LOCAL="Unknown"
    [[ -f "$BASE_DIR/version" ]] && V_LOCAL=$(cat "$BASE_DIR/version" | xargs)
}

# ------------------------------
# 功能：卸载（终止程序）
# ------------------------------
do_uninstall() {
    clear
    exec bash "$INSTALL_DIR/uninstall.sh"
}

# ------------------------------
# 维护模块入口函数
# ------------------------------
vsk_script_menu() {
    while true; do

        # 每次循环刷新版本号，确保更新后重启前显示一致
        _refresh_local_version

        ui clear

        ui print page_header_full "🔄  VpsScriptKit 系统更新中心"

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
                ui clear
                ui print info_header "正在检查更新逻辑..."
                if [[ -f "$BASE_DIR/update.sh" ]]; then
                    # 运行更新引擎并获取退出码
                    bash "$BASE_DIR/update.sh"
                    local exit_code=$?

                    # 如果退出码是 10，更新到新版本，执行顶层重启
                    if [ $exit_code -eq 10 ]; then
                        ui echo "${BOLD_CYAN}🔄 检测到版本变动，正在原地重启脚本...${RESET}"
                        sleep 1
                        exec v
                    fi
                else
                    ui_error "未找到核心更新引擎 update.sh"
                fi
                # 已经是最新，正常等待用户回车返回菜单
                ui_wait_enter
                ;;
            2)
                ui clear
                ui echo "${BOLD_YELLOW}正在强制重新安装并修复环境...${RESET}"
                ui blank

                # 1. 使用 bash -s -- 传递参数给远程下载的脚本
                # 2. 传递 --skip-agreement 让 install.sh 识别并跳过确认环节
                if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
                    ui blank
                    ui echo "${BOLD_GREEN}✅ 强制重新安装完成！${RESET}"
                    ui echo "${BOLD_CYAN}🔄 脚本将在 2 秒后原地重启...${RESET}"
                    sleep 2
                    # 重新载入主程序
                    exec v
                else
                    ui_error "强制安装过程中出现异常"
                    ui_wait_enter
                fi
                ;;
            3)
                do_uninstall
                ;;
            0)
                # 返回上级（由 router 自动处理）
                return
                ;;
            *)
                ui_warn_menu "无效选项，请重新输入..."
                sleep 1
                ;;
        esac
    done
}
