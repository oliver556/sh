#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 更新中心界面
# @名称:         system/maintain.sh
# @职责:
# - VpsScriptKit 更新菜单
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-06
# @修改日期:     2025-01-06
#
# @许可证:       MIT
# ============================================================

# ------------------------------
# 内部工具：实时刷新本地版本显示
# ------------------------------
_refresh_local_version() {
    V_LOCAL="Unknown"
    # 从项目根目录的 version 文件读取最新版本号
    if [[ -f "$BASE_DIR/version" ]]; then
        V_LOCAL=$(cat "$BASE_DIR/version" | xargs)
    fi
}

# ------------------------------
# 维护模块入口函数
# ------------------------------
maintain_entry() {
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
        ui_go_level 0 

        local choice
        choice="$(ui read_choice)"

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
                    ui error "未找到核心更新引擎 update.sh"
                fi
                # 已经是最新，正常等待用户回车返回菜单
                ui wait_return
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
                    ui error "强制安装过程中出现异常"
                    ui wait_return
                fi
                ;;
            # 3)
                # ui clear
                # ui print info_header "📜 最近更新日志"
                # ui line
                # # 实时抓取并格式化展示 GitHub Release 的 Body 内容
                # curl -sL "https://api.github.com/repos/oliver556/sh/releases/latest" | \
                # grep '"body":' | cut -d '"' -f 4 | sed 's/\\r\\n/\n/g' || echo "无法连接到 GitHub 获取日志。"
                # ui line
                # ui wait_return
                # :
                # ;;
            3)
                # 调用根目录下的卸载脚本
                if [[ -f "$BASE_DIR/uninstall.sh" ]]; then
                    # 运行卸载脚本
                    if bash "$BASE_DIR/uninstall.sh"; then
                        # 卸载成功后强制刷新 hash 并退出
                        hash -r 2>/dev/null || true
                        clear
                        exit 0
                    fi
                else
                    ui error "未找到卸载脚本 uninstall.sh"
                    ui wait_return
                fi
                ;;
            0)
                # 返回上级（由 router 自动处理）
                return
                ;;
            *)
                ui error "无效选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}