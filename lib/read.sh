#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - UI 输出
#
# @文件路径: lib/read.sh
# @功能描述:  读取各种输入
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-19
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************

# 导入环境变量
# shellcheck disable=SC1091
source "${BASE_DIR}/lib/print.sh"

# ------------------------------------------------------------------------------
# 函数名: read_input
# 功能:   读取用户输入并赋值给指定变量，支持默认值、正则校验、密码模式
# 
# 参数:
#   $1             (字符串): [必须] 接收输入结果的变量名 (例如: user_name)
#   -m | --msg     (字符串): 提示文本
#   -d | --default (字符串): 默认值 (用户直接回车时使用)
#   -s | --secure  (开关)  : 密码模式 (输入不回显)
#   -r | --required(开关)  : 必填模式 (不能为空)
#   --regex        (字符串): 校验输入的正则表达式
#   --error-msg    (字符串): 正则校验失败时的错误提示
# 
# 示例:
#   read_input user_name -m "请输入用户名" -d "admin"
#   read_input password -m "请输入密码" -s -r
#   read_input ip_addr -m "请输入IP" --regex "^[0-9.]+$" --error-msg "IP格式错误"
# ------------------------------------------------------------------------------
read_input() {
    local prompt=""
    local spaces=3  # 默认缩进为 3
    local icon="${ICON_ARROW}"
    local color="${BOLD_CYAN}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message) prompt="$2"; shift 2 ;;
            -s|--space)   spaces="$2"; shift 2 ;;
            -I|--icon)    icon="$2"; shift 2 ;;
            -c|--color)   color="$2"; shift 2 ;;
            *)
                # 兼容直接传参 read_input "提示内容" "默认值"
                if [[ -z "$prompt" ]]; then
                    prompt="$1"
                fi
                shift 1
                ;;
        esac
    done

    print_echo -ne "${color}${icon}$(print_spaces "$spaces")${prompt}:$(print_spaces 1)${NC}" >&2

    local input_val
    read -r input_val

    print_echo "${input_val}"
}

# ------------------------------------------------------------------------------
# 函数名: read_choice
# 功能:   专门用于菜单选择读取，支持校验有效选项范围，输入无效会自动提示重试
# 
# 参数:
#   $1             (字符串): [必须] 接收结果的变量名
#   -m | --msg     (字符串): 提示文本 (默认: "请输入您的选择")
#   -d | --default (字符串): 默认选项
#   -a | --allowed (字符串): 允许的输入列表 (空格分隔)，例如 "1 2 3 q"
#                            如果不传此参数，则不限制输入内容
# 
# 示例:
#   read_choice choice -m "请选择操作" -a "1 2 3 q" -d "1"
# ------------------------------------------------------------------------------
read_choice() {
    local prompt="请输入选项"
    local spaces=3  # 默认缩进为 3
    local icon="${ICON_ARROW}"
    local color="${BOLD_CYAN}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message) prompt="$2"; shift 2 ;;
            -s|--space)   spaces="$2"; shift 2 ;;
            -I|--icon)    icon="$2"; shift 2 ;;
            -c|--color)   color="$2"; shift 2 ;;
            *)
                # 兼容直接传参 read_input "提示内容" "默认值"
                if [[ -z "$prompt" ]]; then
                    prompt="$1"
                fi
                shift 1
                ;;
        esac
    done

    if [[ $# -eq 0 ]]; then
        read_input -m "$prompt" -s "$spaces" -I "$icon" -c "$color"
    else
        read_input "$@"
    fi
}

read_confirm() {
    local prompt="${1:-确认继续？(y|n)}"

    print_blank

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message) prompt="$2"; shift 2 ;;
            *)
                # 兼容直接传参 read_input "提示内容" "默认值"
                if [[ -z "$prompt" ]]; then
                    prompt="$1"
                fi
                shift 1
                ;;
        esac
    done

    answer=$(read_choice -s 1 -m "$prompt")

    case "$answer" in
        y|yes|Y)
            return 0
            ;;
        n|no|N)
            return 1
            ;;
        *)
            print_echo "操作已取消..."
            sleep 1
            return 1
            ;;
    esac
}