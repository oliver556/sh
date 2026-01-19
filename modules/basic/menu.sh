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
    print_box_info -m "手动指定安装工具" -p bottom

    prompt=$(ui_read_choice --space 1 --prompt "请输入安装的工具名（wget curl）")

    if [[ -z "$prompt" ]]; then
        print_info -m "未提供软件包参数！"
        return 1
    fi

    if command -v "$prompt" &> /dev/null; then
        print_step "$prompt 已安装，跳过安装"
        curl --help
    else
        pkg_install "$prompt"
        print_clear
        print_box_success -m "$prompt 已安装！"
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
    print_box_info -m "手动指定卸载工具" -p bottom

    prompt=$(ui_read_choice --space 1 --prompt "请输入卸载的工具名（wget curl）")

    if [[ -z "$prompt" ]]; then
        print_info -m "未提供软件包参数！"
        return 1
    fi

    if ! command -v "$prompt" &> /dev/null; then
        print_step -m "$prompt 未安装，跳过卸载"
    else
        pkg_remove "$prompt"
        print_clear
        print_box_success -m "$prompt 已卸载！"
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
        print_clear

        print_box_header "${ICON_MAINTAIN}$(ui_spaces 1)基础工具"

      
        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(ui_spaces 1)curl 下载工具" -I star
        print_menu_item -r 2 -p 0 -i 2 -m "$(ui_spaces 1)wget 下载工具" -I star
        print_menu_item_done

        print_line
        print_menu_item -r 31 -p 0 -i 31 -m "全部安装"
        print_menu_item -r 32 -p 0 -i 32 -m "全部卸载"
        print_menu_item_done

        print_line
        print_menu_item -r 41 -p 0 -i 41 -m "安装指定工具"
        print_menu_item -r 42 -p 0 -i 42 -m "卸载指定工具"
        print_menu_item_done

        print_menu_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                print_clear
                if command -v curl &> /dev/null; then
                    print_box_info -m "curl 已安装，跳过安装"
                    curl --help
                else
                    pkg_install curl
                    print_clear
                    print_box_success -m "curl 安装成功！"
                    curl --help
                fi
                print_wait_enter
                ;;
            2)
                print_clear
                if command -v wget &> /dev/null; then
                    print_box_success -m  "wget 已安装，跳过安装"
                    wget --help
                else
                    pkg_install wget
                    print_clear
                    print_box_success -m "wget 安装成功！"
                    wget --help
                fi
                
                print_wait_enter
                ;;
            31)
                print_clear

                print_box_info -m "全部安装..." -s start

                DEPENDENCIES=("curl" "wget")

                for cmd in "${DEPENDENCIES[@]}"; do
                    if ! command -v "$cmd" &> /dev/null; then
                        pkg_install "$cmd"
                    else
                        print_box_success -m "$cmd 已安装"
                    fi
                done

                print_box_info -m "全部安装" -s success

                print_wait_enter
                ;;
            32)
                print_clear

                print_box_info -m "全部卸载..." -s start

                DEPENDENCIES=("curl" "wget")

                for cmd in "${DEPENDENCIES[@]}"; do
                # TOD 没有显示卸载步骤
                    if command -v "$cmd" &> /dev/null; then
                        pkg_remove "$cmd"
                    else
                        print_box_success -m "$cmd 已卸载"
                    fi
                done

                print_box_info -m "全部卸载" -s success

                print_wait_enter
                ;;
            41)
                print_clear
                _pdk_install_prompt
                print_wait_enter
                ;;
            42)
                print_clear
                _pdk_remove_prompt
                print_wait_enter
                ;;
            0)
                return
                ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}