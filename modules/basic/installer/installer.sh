#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 软件安装中心
#
# @文件路径: modules/basic/installer/installer.sh
# @功能描述: 软件安装中心 - 导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-13
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
# shellcheck disable=SC1091
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

    prompt=$(read_choice -s 1 -m "请输入安装的工具名（wget curl）")

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

    prompt=$(read_choice -s 1 -m "请输入卸载的工具名（wget curl）")

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
    fi
}

# ------------------------------------------------------------------------------
# 函数名: install_menu
# 功能:   软件安装中心导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   install_menu
# ------------------------------------------------------------------------------
install_menu() {
  while true; do
        print_clear

        print_box_header "${ICON_MAINTAIN}$(print_spaces 1)软件安装中心 (Software Center)"

      
        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(print_spaces 1)curl 下载工具" -I star
        print_menu_item -r 2 -p 0 -i 2 -m "$(print_spaces 1)wget 下载工具" -I star
        print_menu_item -r 3 -p 0 -i 3 -m "$(print_spaces 1)Tmux 终端复用管理" -I star
        # [ 环境安装 ]
        #  1. 安装 Curl / Wget / Git
        #  2. 安装 Vim / Nano
        #  3. 安装 Python / Nodejs环境
        #  5. Tmux 终端复用管理
        #  6. Zsh 终端主题切换
        #  7. Fail2ban 防护管理
        # 2.  版本控制工具 (Git/Svn)
        # 3.  网络诊断工具 (Ping/Traceroute/Mtr)
        # 4.  解压压缩工具 (Zip/Tar/Unzip)
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

        refresh_hash

        choice=$(read_choice)

        case "$choice" in
            1)
                print_clear
                if command -v curl &> /dev/null; then
                    print_box_info -m "curl 已安装，跳过安装"
                    curl --help
                else
                    pkg_install curl
                    print_clear
                    print_box_success -s finish -m "curl 安装成功！"
                    curl --help
                fi
                print_wait_enter
                ;;
            2)
                print_clear
                if command -v wget &> /dev/null; then
                    print_box_success -s finish -m "wget 已安装，跳过安装"
                    wget --help
                else
                    pkg_install wget
                    print_clear
                    print_box_success -s finish -m "wget 安装成功！"
                    wget --help
                fi
                
                print_wait_enter
                ;;
            3)
                print_clear
                # 1. 检查是否已存在
                if command -v tmux &> /dev/null; then
                    print_box_info -m "tmux 已安装，跳过安装"
                    # 显示版本号，证明它存在且可用
                    print_echo "当前版本: $(tmux -V)"
                else
                    # 2. 执行安装
                    pkg_install tmux
                    
                    # 3. 验证是否安装成功
                    if command -v tmux &> /dev/null; then
                        print_clear
                        print_box_success -s finish -m "tmux 安装成功！"
                        print_echo "当前版本: $(tmux -V)"
                    else
                        print_error "tmux 安装失败，请尝试手动运行包管理器安装。"
                    fi
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
                        print_box_success -s finish -m "$cmd 已安装"
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
                        print_box_success -s finish -m "$cmd 已卸载"
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