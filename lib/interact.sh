#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 交互确认工具
#
# @文件路径: lib/interact.sh
# @功能描述: 负责 “问” (确认框、输入框、等待按键)。
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-30
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: ui_spaces
# 功能:   生成指定数量的空格字符串
# 
# 参数:
#   $1 (number): 需要的空格数量 (可选)
# 
# 返回值: 需要的空格数量
# 
# 示例:
#   "A$(ui_spaces 2)B"
# ------------------------------------------------------------------------------
ui_spaces() {
    local count="${1:-2}"
    ((count < 0)) && count=0
    printf "%*s" "$count" ""
}

# ------------------------------------------------------------------------------
# 函数名: ui_confirm
# 功能:   按 (Y/y) 键确认，按其它任意键返回/取消
# 
# 参数:
#   $1 (number): 提示信息 (默认: 确认执行此操作吗？)
# 
# 返回值:
#   0 - 确认
#   1 - 取消
# 
# 示例:
#  if ! ui_confirm " 注意: 确定***吗？; then
#      return 1
#  fi
# ------------------------------------------------------------------------------
ui_confirm() {
    local title="$1"
    local user_choice

    print_blank
    # 如果 title 不为空，则显示具体的标题提示
    if [ -n "$title" ]; then
        print_echo "${BOLD_WHITE}按${NC} ${BOLD_RED}(Y/y)${BOLD_WHITE} 键确认执行 ${BOLD_CYAN}${title}${BOLD_WHITE}，按其它任意键返回。"
    else
        print_echo "${BOLD_WHITE}按${NC} ${BOLD_RED}(Y/y)${BOLD_WHITE} 键确认执行，按其它任意键返回。"
    fi
    
    print_blank

    user_choice=$(ui_read_choice --space 1 --prompt "请输入选项")

    case "$user_choice" in
        y|Y)
            return 0  # 返回 0, 代表“确认/继续”
            ;;
        *)
            echo -e "\n${BOLD_YELLOW}操作已取消...${BOLD_WHITE}"
            sleep 1
            return 1  # 返回 1, 代表“失败/取消”
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: ui_wait
# 功能:  流程中的临时暂停，“任意键“ 继续
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   ui_wait
# ------------------------------------------------------------------------------
ui_wait() {
    print_blank
    print_echo "${BOLD_CYAN}按任意键继续...${BOLD_WHITE}"
    # -n 1: 读取 1 个字符立即返回
    # -s: 静默模式，不回显输入
    # -r: 允许反斜杠
    read -n 1 -s -r
}

# ------------------------------------------------------------------------------
# 函数名: ui_return
# 功能:   直接返回，不等待任何输入
#
# 参数: 无
#
# 返回值: 无
#
# 示例:
#   ui_return
# ------------------------------------------------------------------------------
ui_return() {
    # 可选提示信息，但默认不显示
    # print_blank
    # print_echo "${BOLD_WHITE}执行完成，自动返回...${BOLD_WHITE}"
    # 直接返回，不等待输入
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: ui_input
# 功能:   获取用户输入的文本数据。支持设置默认值
# 
# 参数:
#   $1 (string): 提示语 (必填)
#   $2 (string): 自定义描述
#   $3 (number): 间距
# 
# 返回值: 返回 echo 的值
# 
# 示例:
#   ui_input "$1"
# ------------------------------------------------------------------------------
ui_input() {
    local prompt=""
    local default_val=""
    local space=3  # 默认间距为 3

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prompt) prompt="$2"; shift 2 ;;
            --default) default_val="$2"; shift 2 ;;
            --space) space="$2"; shift 2 ;;
            *) 
                # 兼容旧的顺序调用：如果第一个参数不是以--开头，认为是prompt
                if [[ -z "$prompt" ]]; then
                    prompt="$1";
                else
                    default_val="$1";
                fi
                shift 1 ;;
        esac
    done

    local input_val
    local prefix="${BOLD_CYAN}➜$(ui_spaces "$space")"
    
    if [ -n "$default_val" ]; then
        # 带有默认值的提示
        read -rp "$(print_echo "${prefix}${prompt} [默认: ${BOLD_WHITE}${default_val}${BOLD_CYAN}]: ${NC}")" input_val
        print_echo "${input_val:-$default_val}"
    else
        # 普通提示
        read -rp "$(print_echo "${prefix}${prompt}: ${NC}")" input_val
        print_echo "$input_val"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ui_read_choice
# 功能:   专门用于菜单选择的读取。作为 ui_input 的快捷封装。
# 
# 参数:
#   $1 (string): 提示文字 (可选)
# 
# 返回值:
#   返回提示内容
# 
# 示例:
#   ui_read_choice "$1"
# ------------------------------------------------------------------------------
ui_read_choice() {
    # 如果没有任何参数，则给定默认提示语
    if [[ $# -eq 0 ]]; then
        ui_input --prompt "请输入选项"
    else
        # 将所有参数 ($@) 转发给 ui_input
        ui_input "$@"
    fi
}
