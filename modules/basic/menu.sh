#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 基础工具
#
# @文件路径: modules/basic/menu.sh
# @功能描述: 提供基础工具导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-13
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
source "${BASE_DIR}/lib/package.sh"

# ------------------------------------------------------------------------------
# 函数名: _pdk_install_prompt
# 功能:   安装指定报名辅助
# 
# 参数:
#   $1 (string): 要安装的包名 (必填)
# 
# 返回值:
#   无
# 
# 示例:
#   _pdk_install_prompt
# ------------------------------------------------------------------------------
_pdk_install_prompt() {
    ui_box_info "手动指定安装工具" "bottom"

    local prompt="${1:-请输入安装的工具名（wget curl）}"
    local choice=$(ui_input "$prompt")

    if [[ -z "$choice" ]]; then
        ui_tip "未提供软件包参数！"
        return 1
    fi

    pkg_install $choice
}

# ------------------------------------------------------------------------------
# 函数名: _pdk_remove_prompt
# 功能:   卸载指定报名辅助
# 
# 参数:
#   $1 (string): 要卸载的包名 (必填)
# 
# 返回值:
#   无
# 
# 示例:
#   _pdk_remove_prompt
# ------------------------------------------------------------------------------
_pdk_remove_prompt() {
    ui_box_info "手动指定卸载工具" "bottom"

    local prompt="${1:-请输入安装的工具名（wget curl）}"
    local choice=$(ui_input "$prompt")

    if [[ -z "$choice" ]]; then
        ui_tip "未提供软件包参数！"
        return 1
    fi

    pkg_install $choice
}

# ------------------------------------------------------------------------------
# 函数名: basic_menu
# 功能:   基础工具导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   basic_menu
# ------------------------------------------------------------------------------
basic_menu() {
  while true; do
        ui clear

        ui print page_header_full "🛠️$(ui_spaces)基础工具"
      
        ui line
        # --- 操作选单 ---
        ui_menu_item 1 0 1 "$(ui_spaces 1)curl 下载工具 ${BOLD_YELLOW}★${LIGHT_WHITE}"
        ui_menu_item 1 10 2 "wget 下载工具 ${BOLD_YELLOW}★${LIGHT_WHITE}"
        ui_menu_done

        ui line
        ui_menu_item 1 0 31 "全部安装"
        ui_menu_item 1 16 32 "全部卸载"
        ui_menu_done

        ui line
        ui_menu_item 1 0 41 "安装指定工具"
        ui_menu_item 1 12 42 "卸载指定工具"
        ui_menu_done

        ui_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                ui clear
                pkg_install curl
                ui clear
                ui_box_success "curl 下载工具安装成功！"
                curl --help
                ui_wait_enter
                ;;
            2)
                ui clear
                pkg_install wget
                ui clear
                ui_box_success "curl 下载工具安装成功！"
                curl --help
                ui_wait_enter
                ;;
            31)
                ui clear
                pkg_remove curl wget
                ;;
            41)
                ui clear
                _pdk_install_prompt
                ui_wait_enter
                ;;
            42)
                ui clear
                _pdk_remove_prompt
                ui_wait_enter
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