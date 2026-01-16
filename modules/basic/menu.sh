#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 基础工具
#
# @文件路径: modules/basic/menu.sh
# @功能描述: 基础工具导航页
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

    prompt=$(ui_read_choice --space 1 --prompt "请输入安装的工具名（wget curl）")

    if [[ -z "$prompt" ]]; then
        print_info "未提供软件包参数！"
        return 1
    fi

    if command -v "$prompt" &> /dev/null; then
        ui_box_info "$prompt 已安装，跳过安装"
        curl --help
    else
        pkg_install "$prompt"
        ui clear
        ui_box_success "$prompt 已安装！"
        curl --help
    fi
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

    prompt=$(ui_read_choice --space 1 --prompt "请输入卸载的工具名（wget curl）")

    if [[ -z "$prompt" ]]; then
        print_info "未提供软件包参数！"
        return 1
    fi

    if ! command -v "$prompt" &> /dev/null; then
        ui_box_info "$prompt 未安装，跳过卸载"
    else
        pkg_remove "$prompt"
        ui clear
        ui_box_success "$prompt 已卸载！"
        curl --help
    fi
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

        ui print page_header "⚒$(ui_spaces 1)基础工具"
      
        ui line
        # --- 操作选单 ---
        ui_menu_item 1 0 1 "$(ui_spaces 1)curl 下载工具 ${BOLD_YELLOW}★${BOLD_WHITE}"
        ui_menu_item 1 10 2 "wget 下载工具 ${BOLD_YELLOW}★${BOLD_WHITE}"
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
                if command -v curl &> /dev/null; then
                    ui_box_info "curl 已安装，跳过安装"
                    curl --help
                else
                    pkg_install curl
                    ui clear
                    ui_box_success "curl 安装成功！"
                    curl --help
                fi
                ui_wait_enter
                ;;
            2)
                ui clear
                if command -v wget &> /dev/null; then
                    ui_box_info "wget 已安装，跳过安装"
                    wget --help
                else
                    pkg_install wget
                    ui clear
                    ui_box_success "wget 安装成功！"
                    wget --help
                fi

                
                ui_wait_enter
                ;;
            31)
                ui clear
                DEPENDENCIES=("curl" "wget")

                for cmd in "${DEPENDENCIES[@]}"; do
                    if ! command -v "$cmd" &> /dev/null; then
                        ui_tip "$cmd 未安装，正在安装..."
                        pkg_install "$cmd"
                    else
                        ui_box_success "$cmd 已安装"
                    fi
                done

                ui_wait_enter
                ;;
            32)
                ui clear
                DEPENDENCIES=("curl" "wget")

                for cmd in "${DEPENDENCIES[@]}"; do
                    if command -v "$cmd" &> /dev/null; then
                        ui_tip "$cmd 已安装，正在卸载..."
                        pkg_remove "$cmd"
                    else
                        ui_box_success "$cmd 已卸载"
                    fi
                done

                ui_wait_enter
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