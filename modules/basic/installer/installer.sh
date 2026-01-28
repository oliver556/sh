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

# 定义本模块管理的软件列表
APPS_LIST=(
    # --- 基础下载与连接 ---
    "curl"
    "wget"
    "sudo"
    "socat"
    # --- 生产力与解压 ---
    "git"
    "tmux"
    "tar"
    "unzip"
     # --- 编辑器 ---
    "vim"
    "nano"
    # --- 监控与管理 ---
    "btop"
    "ncdu"
)

# ------------------------------------------------------------------------------
# 函数名: _draw_software_status
# 功能:   使用 print_status_item 绘制软件状态
# ------------------------------------------------------------------------------
_draw_software_status() {
    # 1. 顶部包管理器信息
    local pm_display="${GRAY}未知${NC}"
    if command -v apt-get &>/dev/null; then pm_display="${BOLD_CYAN}apt (Debian/Ubuntu)${NC}";
    elif command -v dnf &>/dev/null; then pm_display="${BOLD_CYAN}dnf (CentOS 8+/Fedora)${NC}";
    elif command -v yum &>/dev/null; then pm_display="${BOLD_CYAN}yum (CentOS 7)${NC}";
    elif command -v apk &>/dev/null; then pm_display="${BOLD_CYAN}apk (Alpine)${NC}";
    fi
    
    # 顶部渲染
    print_status_item -l "包管理器:" -v "${pm_display}" -w 12
    print_status_done
    print_line -c "─" -C "${GRAY}"

    # 2. 定义双列布局参数
    local L_W=12  # 左侧标签宽度
    local V_W=9   # 左侧数值预留宽度
    local PAD=0   # 整体左缩进

    local apps=("${APPS_LIST[@]}")

    # 4. 循环渲染
    # 这里的逻辑是：每两个一组，第一列设置 -W (ValWidth)，第二列不设置
    local i=0
    local total=${#apps[@]}

    for ((i=0; i<total; i+=2)); do
        local cmd1="${apps[i]}"
        local cmd2="${apps[i+1]:-}"
        local row_id=$((i/2)) # 生成行号 0, 1, 2...

        # --- 处理第一列 ---
        local label1="${cmd1^}"  # 【自动首字母大写
        local status1="${GRAY}✘ 未安装${NC}"
        if command -v "$cmd1" &>/dev/null; then status1="${GREEN}✔ 已安装${NC}"; fi
        
        # 第一列总是有 -W 参数
        print_status_item -r "$row_id" -p "$PAD" -l "${label1}:" -v "${status1}" -w "$L_W" -W "$V_W"

        # --- 处理第二列 (如果存在) ---
        if [[ -n "$cmd2" ]]; then
            local label2="${cmd2^}" # 自动首字母大写
            local status2="${GRAY}✘ 未安装${NC}"
            if command -v "$cmd2" &>/dev/null; then status2="${GREEN}✔ 已安装${NC}"; fi
            
            # 第二列不需要 -W
            print_status_item -r "$row_id" -l "${label2}:" -v "${status2}" -w "$L_W"
        fi
    done
    
    print_status_done
}

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
    print_box_info -m "手动指定安装工具"

    prompt=$(read_choice -s 1 -m "请输入工具名 (多个用空格分隔)")

    if [[ -n "$prompt" ]]; then
        pkg_install "$prompt"
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
    print_box_info -m "手动指定卸载工具"

    prompt=$(read_choice -s 1 -m "请输入工具名 (多个用空格分隔)")

    if [[ -n "$prompt" ]]; then
        pkg_remove "$prompt"
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
        _draw_software_status

        print_line
        print_step -m "基础下载与连接"
        print_menu_item -r 1 -p 0 -i 1 -m "$(print_spaces 1)curl  下载工具" -I star
        print_menu_item -r 1 -p 9 -i 2 -m "$(print_spaces 1)wget  下载工具" -I star
        print_menu_item -r 2 -p 0 -i 3 -m "$(print_spaces 1)sudo  超级管理权限工具"
        print_menu_item -r 2 -p 2 -i 4 -m "$(print_spaces 1)socat 通信连接工具"
        print_menu_item_done

        print_line
        print_step -m  "生产力与解压"
        print_menu_item -r 3 -p 0 -i 5 -m "$(print_spaces 1)git   版本控制系统"
        print_menu_item -r 3 -p 6 -i 6 -m "$(print_spaces 1)tmux  终端复用管理"
        print_menu_item -r 4 -p 0 -i 7 -m "$(print_spaces 1)tar   GZ压缩解压工具"
        print_menu_item -r 4 -p 4 -i 8 -m "$(print_spaces 1)unzip ZIP压缩解压工具"
        print_menu_item_done

        print_line
        print_step -m  "编辑器"
        print_menu_item -r 5 -p 0 -i 9 -m "$(print_spaces 1)vim   文本编辑器"
        print_menu_item -r 5 -p 7 -i 10 -m "$(print_spaces 1)nano  文本编辑器"
        print_menu_item_done
        
        print_line
        print_step -m  "监控与管理"
        print_menu_item -r 6 -p 0 -i 11 -m "$(print_spaces 1)btop 现代化监控工具"
        print_menu_item -r 6 -p 3 -i 12 -m "$(print_spaces 1)ncdu  磁盘占用查看工具"
        print_menu_item_done

        # print_line
        # print_step -m  "系统环境"
        # print_menu_item -r 51 -p 0 -i 51 -m "$(print_spaces 1)Python"
        # print_menu_item -r 51 -p 16 -i 52 -m "$(print_spaces 1)Nodejs"
        # print_menu_item_done
 
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
                pkg_install curl
                print_wait_enter
                ;;
            2)
                print_clear
                pkg_install wget
                print_wait_enter
                ;;
            3)
                print_clear
                pkg_install sudo
                print_wait_enter
                ;;
            4)
                print_clear
                pkg_install socat
                print_wait_enter
                ;;
            5)
                print_clear
                pkg_install git
                print_wait_enter
                ;;
            6)
                print_clear
                pkg_install tmux
                print_wait_enter
                ;;
            7)
                print_clear
                pkg_install tar
                print_wait_enter
                ;;
            8)
                print_clear
                pkg_install unzip
                print_wait_enter
                ;;
            9)
                print_clear
                pkg_install vim
                print_wait_enter
                ;;
            10)
                print_clear
                pkg_install nano
                print_wait_enter
                ;;
            11)
                print_clear
                pkg_install btop
                print_wait_enter
                ;;
            12)
                print_clear
                pkg_install ncdu
                print_wait_enter
                ;;
            31)
                print_clear
                print_box_info -m "批量安装核心工具..." -s start
                pkg_install "${APPS_LIST[@]}"
                print_box_info -m "批量安装核心工具" -s success
                print_wait_enter
                ;;
            32)
                print_clear
                print_box_info -m "批量卸载核心工具..." -s start
                pkg_remove "${APPS_LIST[@]}"
                print_box_info -m "批量卸载核心工具" -s success
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