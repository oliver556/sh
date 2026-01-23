#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - UI 输出
#
# @文件路径: lib/print.sh
# @功能描述: 负责 “画” (UI 渲染、菜单项、颜色、间距)
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-31
# ==============================================================================

# ******************************************************************************
# UI 输出函数
# ******************************************************************************

# 基础输出，默认 -e
print_echo () {
    echo -e "$@"
}

# 换行输出
print_blank() {
    print_echo ""
}

# 清屏输出
print_clear() {
    clear
}

# 脚本退出输出
print_exit() {
    print_clear
    print_line
    print_info -C "$BOLD_GREEN" -I "$ICON_EXIT" -m "感谢使用 VpsScriptKit"
    print_info -C "$BOLD_CYAN" -I "$ICON_EXIT" -m "江湖有缘再见。"
    print_line
    sleep 1
    print_clear
    exit 0
}

# ------------------------------------------------------------------------------
# 函数名: print_spaces
# 功能:   生成指定数量的空格字符串
# 
# 参数:
#   $1 (number): 需要的空格数量 (可选)
# 
# 返回值: 需要的空格数量
# 
# 示例:
#   "A$(print_spaces 2)B"
# ------------------------------------------------------------------------------
print_spaces() {
    local count="${1:-2}"
    ((count < 0)) && count=0
    printf "%*s" "$count" ""
}

# ------------------------------------------------------------------------------
# 函数名: print_wait
# 功能:  流程中的临时暂停，“任意键“ 继续
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   print_wait
# ------------------------------------------------------------------------------
print_wait() {
    print_blank
    print_echo "${BOLD_CYAN}按任意键继续...${BOLD_WHITE}"
    # -n 1: 读取 1 个字符立即返回
    # -s: 静默模式，不回显输入
    # -r: 允许反斜杠
    read -n 1 -s -r
}

# ------------------------------------------------------------------------------
# 函数名: print_wait_enter
# 功能:   流程中的临时暂停，“回车键“ 继续
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   print_wait_enter
# ------------------------------------------------------------------------------
print_wait_enter() {
    print_blank
    print_echo "${BOLD_GREEN}执行完成${BOLD_WHITE}"
    print_echo "${BOLD_WHITE}按回车键继续...${BOLD_WHITE}"
    # 不带 -n，强制等待回车
    # -s: 静默模式，不回显输入
    # -r: 允许反斜杠
    read -s -r
}

# ------------------------------------------------------------------------------
# 函数名: print_line
# 功能:   打印一条横跨终端宽度的水平分割线，支持自定义填充字符、颜色及边缘装饰
# 
# 参数:
#   -c | --char   (字符串): 中间填充字符，默认为 "─" (可选)
#   -C | --color  (变量)  : 线条颜色，需传入颜色变量如 "$RED"，默认为 "${BOLD_CYAN}" (可选)
#   -e | --edge   (字符串): 两端边缘装饰符号，如 "+" 或 "|"，默认为空 (可选)
#   $1            (字符串): (兜底) 若不使用 Flag，直接传入的第一个参数将被视为填充字符
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_line                          # 打印默认样式的线
#   print_line "="                      # 打印等号线
#   print_line -c "*" -C "$RED"         # 打印红色星号线
#   print_line -c "=" -e "+" -C "$BLUE" # 打印蓝色虚线，且两端带加号 (+=======+)
# ------------------------------------------------------------------------------
# shellcheck disable=SC2120
print_line() {
    local char="─"
    local color="${BOLD_CYAN}" # 默认颜色
    local edge=""              # 默认两端为空
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--char)
                char="$2"
                shift 2
                ;;
            -C|--color)
                color="$2"
                shift 2
                ;;
            -e|--edge)  # <--- 新增参数：指定两端的符号
                edge="$2"
                shift 2
                ;;
            *)
                # 兜底：如果直接传了字符 (且不是以 - 开头的参数)
                if [[ "$1" != -* ]]; then
                    char="$1"
                fi
                shift 1
                ;;
        esac
    done

    # 获取屏幕宽度
    local width
    width=$(tput cols 2>/dev/null || echo 80)

    # 如果指定了边缘符号 (比如 +)，中间的线就要变短 2 格
    if [[ -n "$edge" ]]; then
        (( width = width - 2 ))
    fi

    local line_str
    printf -v line_str "%*s" "$width" ""
    line_str="${line_str// /$char}"
    
    # 颜色 + 左边缘 + 中间线 + 右边缘 + 结束颜色
    print_echo "${color}${edge}${line_str}${edge}${NC}"
}

# ------------------------------------------------------------------------------
# 函数名: print_info
# 功能:   打印带有图标、颜色和缩进格式的信息提示文本
# 
# 参数:
#   -s | --spaces  (整数)  : 缩进层级，默认为 1 (也就是 print_spaces 1) (可选)
#   -m | --msg     (字符串): 消息内容文本 (可选)
#   -C | --color   (变量)  : 文本颜色，需传入颜色变量如 "$RED"，默认为 "${BLUE}" (可选)
#   -I | --icon    (字符串): 前缀图标/标签内容 (可选)
#   $1             (字符串): (兜底) 若不使用 Flag，直接传入的内容将被视为消息文本
# 
# 返回值:
#   0 - 成功打印
#   (无返回值) - 如果消息内容为空，则直接返回不执行
# 
# 示例:
#   print_info "正在初始化..."                  # 默认缩进1，蓝色
#   print_info -s 4 "子任务详情"                # 缩进4格
#   print_info -C "$GREEN" "操作成功"           # 绿色文本
#   print_info -s 2 -C "$RED" --msg "发生错误"  # 混合使用
# ------------------------------------------------------------------------------
print_info() {
    local message=""
    local spaces=1  # 默认缩进为 1
    local color="${BLUE}" # 默认颜色
    local icon="${ICON_INFO}"


    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--spaces)
                spaces="$2"
                shift 2
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            -C|--color)
                color="$2"
                shift 2
                ;;
            -I|--icon)
                icon="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：支持直接传文本，不带 --msg
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 如果没有消息内容，直接返回 (对应原代码的 [[ $# -eq 0 ]] && return)
    if [[ -z "$message" ]]; then
        return
    fi

    # 执行输出
    print_echo "${color}${icon}$(print_spaces "$spaces")${message}${NC}"
}

# ------------------------------------------------------------------------------
# 函数名: print_success
# 功能:   打印带有“成功”图标（通常是勾号）和绿色文本的提示信息
# 
# 参数:
#   -s | --spaces  (整数)  : 缩进层级，默认为 1 (即 print_spaces 1) (可选)
#   -m | --msg     (字符串): 消息内容文本 (可选)
#   $1             (字符串): (兜底) 若不使用 Flag，直接传入的内容将被视为消息文本
# 
# 返回值:
#   0 - 成功打印
#   (无返回值) - 如果消息内容为空，则直接返回不执行
# 
# 示例:
#   print_success "安装完成"                   # 默认缩进1，绿色
#   print_success -s 2 "依赖项检查通过"        # 缩进2格
#   print_success -m "配置文件已更新"          # 显式指定消息
# ------------------------------------------------------------------------------
print_success() {
    local message=""
    local spaces=1  # 默认缩进为 1

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--spaces)
                spaces="$2"
                shift 2
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：支持直接传文本，不带 --msg
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 如果没有消息内容，直接返回 (对应原代码的 [[ $# -eq 0 ]] && return)
    if [[ -z "$message" ]]; then
        return
    fi

    # 执行输出
    print_echo "${GREEN}${ICON_OK}$(print_spaces "$spaces")${message}${NC}"
}

# 警告输出
print_warn() {
    local message=""
    local spaces=1  # 默认缩进为 1

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--spaces)
                spaces="$2"
                shift 2
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：支持直接传文本，不带 --msg
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 如果没有消息内容，直接返回 (对应原代码的 [[ $# -eq 0 ]] && return)
    if [[ -z "$message" ]]; then
        return
    fi

    # 执行输出
    print_echo "${YELLOW}${ICON_WARNING}$(print_spaces "$spaces")${message}${NC}"
}
# 错误输出
print_error() {
    local message=""
    local spaces=1  # 默认缩进为 1

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--spaces)
                spaces="$2"
                shift 2
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：支持直接传文本，不带 --msg
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 如果没有消息内容，直接返回 (对应原代码的 [[ $# -eq 0 ]] && return)
    if [[ -z "$message" ]]; then
        return
    fi

    # 执行输出
    print_echo "${RED}${ICON_FAIL}$(print_spaces "$spaces")${message}${NC}"
}

# 步骤输出
print_step() {
    local message=""
    local spaces=1  # 默认缩进为 1

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--spaces)
                spaces="$2"
                shift 2
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：支持直接传文本，不带 --msg
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 如果没有消息内容，直接返回 (对应原代码的 [[ $# -eq 0 ]] && return)
    if [[ -z "$message" ]]; then
        return
    fi

    # 执行输出
    print_echo "${PURPLE}${ICON_ARROW}$(print_spaces "$spaces")${message}${NC}"
}

print_tip() {
    [[ $# -eq 0 ]] && return
    local message="$*"
    print_echo "${WHITE}${ICON_ARROW}$(print_spaces 1)${message}${NC}"
}

# ******************************************************************************
# 状态反馈 (一般用于执行各种自动化时的内容输出做切割)
# ******************************************************************************
log_info() {
    print_echo "${BOLD_GREEN}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

log_warn() {
    print_echo "${BOLD_YELLOW}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

log_error() {
    print_echo "${BOLD_RED}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

# ------------------------------------------------------------------------------
# 函数名: print_box_info
# 功能:   打印一个带有上下边框的“盒子”式样信息块，常用于区分任务阶段或重要通知
#         会自动将 status (如 start) 转换为格式化的标签 (如 [开始])
# 
# 参数:
#   -s | --status  (字符串): 状态标识，支持 start/begin(显示[开始])、ok/success(显示[完成]) 或自定义
#   -m | --msg     (字符串): 消息内容文本
#   -p | --padding (字符串): 上下留白控制，支持 top, bottom, both, all (默认为空)
#   -C | --color   (变量)  : 整体颜色（标签及边框），默认为 "${BOLD_CYAN}"
#   $1             (字符串): (兜底) 若不使用 Flag，直接传入的内容将被视为消息文本
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_box_info -s start -m "开始清理缓存..."    # 默认青色盒子，显示 [开始]
#   print_box_info -s ok -m "清理完成"              # 显示 [完成]
#   print_box_info -m "这是一个普通通知盒子"        # 无标签，只有边框
#   print_box_info -s error -m "操作失败" -C "$RED" # 红色盒子，显示 [Error]
#
#   print_box_info --status start --msg "清理系统"
#   print_box_success --status finish --msg "清理系统"
# ------------------------------------------------------------------------------
print_box_info() {
    local status=""
    local message=""
    local padding=""
    local color="${BOLD_CYAN}" # 默认颜色

    # $# 表示剩余参数的个数，只要还有参数就继续循环
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--status)
                status="$2"
                shift 2 # 吃掉 "--status" 和 "具体的状体值"，指针向后移两位
                ;;
            -m|--msg|--message) # 支持 --msg 或 --message
                message="$2"
                shift 2
                ;;
            -p|--padding)
                padding="$2"
                shift 2
                ;;
            -C|--color)
                color="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：如果有没加 --前缀的参数，默认追加到消息里
                # 这样即使你偶尔懒得写 --msg，直接写文本也能兼容
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 处理状态标签格式
    local label=""
    if [[ -n "$status" ]]; then
        case "$status" in
            start|begin)
                label="${color}[开始]${NC}"
                ;;
            success|finish|ok)
                label="${color}[完成]${NC}"
                ;;
            *)
                # 自动首字母大写
                local first_char
                first_char=$(echo "${status:0:1}" | tr '[:lower:]' '[:upper:]')
                label="${BOLD}[${first_char}${status:1}]${NC}"
                ;;
        esac
    fi

    # 拼接最终显示的文本 (如果 status 为空，前面就没有空格)
    local final_text=""
    if [[ -n "$label" ]]; then
        final_text="$label $message"
    else
        final_text="$message"
    fi

    # UI 渲染逻辑
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi

    print_line -C "$color"
    print_info --msg "$final_text" -C "$color"
    print_line -C "$color"

    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi
}

# ------------------------------------------------------------------------------
# 函数名: print_box_success
# 功能:   打印一个绿色主题的“成功”状态盒子，包含绿色上下边框和成功图标(√)
#         常用于脚本执行结束后的最终成功提示
# 
# 参数:
#   -s | --status  (字符串): 状态标识，如 ok/finish (显示绿色[完成])，默认为空 (可选)
#   -m | --msg     (字符串): 消息内容文本
#   -p | --padding (字符串): 上下留白控制，支持 top, bottom, both, all (默认为空)
#   $1             (字符串): (兜底) 若不使用 Flag，直接传入的内容将被视为消息文本
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_box_success "部署成功"                    # 只有消息和边框
#   print_box_success -s ok -m "系统清理完毕"       # 显示 [完成] 标签
#   print_box_success -s finish -p both "所有任务结束" 
# ------------------------------------------------------------------------------
print_box_success() {
    local status=""
    local message=""
    local padding=""

    # $# 表示剩余参数的个数，只要还有参数就继续循环
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--status)
                status="$2"
                shift 2 # 吃掉 "--status" 和 "具体的状体值"，指针向后移两位
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            -p|--padding)
                padding="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：如果有没加 --前缀的参数，默认追加到消息里
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 处理状态标签格式 (start -> [Start])
    local label=""
    if [[ -n "$status" ]]; then
        case "$status" in
            start|begin)
                label="${BOLD}[开始]${NC}"
                ;;
            success|finish|ok)
                label="${BOLD}[完成]${NC}"
                ;;
            *)
                # 自动首字母大写
                local first_char
                first_char=$(echo "${status:0:1}" | tr '[:lower:]' '[:upper:]')
                label="${BOLD}[${first_char}${status:1}]${NC}"
                ;;
        esac
    fi

    # 拼接最终显示的文本 (如果 status 为空，前面就没有空格)
    local final_text=""
    if [[ -n "$label" ]]; then
        final_text="$label $message"
    else
        final_text="$message"
    fi

    # UI 渲染逻辑
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi

    print_line -C "$BOLD_GREEN"
    print_success --msg "$final_text"
    print_line -C "$BOLD_GREEN"

    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi
}

# ------------------------------------------------------------------------------
# 函数名: print_box_error
# 功能:   打印一个红色主题的“成功”状态盒子，包含红色上下边框和成功图标(√)
#         常用于脚本执行结束后的最终成功提示
# 
# 参数:
#   -s | --status  (字符串): 状态标识，如 ok/finish (显示绿色[完成])，默认为空 (可选)
#   -m | --msg     (字符串): 消息内容文本
#   -p | --padding (字符串): 上下留白控制，支持 top, bottom, both, all (默认为空)
#   $1             (字符串): (兜底) 若不使用 Flag，直接传入的内容将被视为消息文本
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_box_error "部署失败"                    # 只有消息和边框
#   print_box_error -s ok -m "系统清理失败"       # 显示 [完成] 标签
#   print_box_error -s finish -p both "所有任务结束" 
# ------------------------------------------------------------------------------
print_box_error() {
    local status=""
    local message=""
    local padding=""

    # $# 表示剩余参数的个数，只要还有参数就继续循环
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--status)
                status="$2"
                shift 2 # 吃掉 "--status" 和 "具体的状体值"，指针向后移两位
                ;;
            -m|--msg|--message)
                message="$2"
                shift 2
                ;;
            -p|--padding)
                padding="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑：如果有没加 --前缀的参数，默认追加到消息里
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done

    # 处理状态标签格式 (start -> [Start])
    local label=""
    if [[ -n "$status" ]]; then
        case "$status" in
            start|begin)
                label="${BOLD}[开始]${NC}"
                ;;
            success|finish|ok)
                label="${BOLD}[完成]${NC}"
                ;;
            *)
                # 自动首字母大写
                local first_char
                first_char=$(echo "${status:0:1}" | tr '[:lower:]' '[:upper:]')
                label="${BOLD}[${first_char}${status:1}]${NC}"
                ;;
        esac
    fi

    # 拼接最终显示的文本 (如果 status 为空，前面就没有空格)
    local final_text=""
    if [[ -n "$label" ]]; then
        final_text="$label $message"
    else
        final_text="$message"
    fi

    # UI 渲染逻辑
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi

    print_line -C "$BOLD_RED"
    print_error -m "$final_text"
    print_line -C "$BOLD_RED"

    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        print_blank
    fi
}

# ------------------------------------------------------------------------------
# 函数名: print_box_header
# 功能:   打印带有装饰性边框（两端加号，中间等号）的主菜单标题
#         通常用于脚本运行的最开始，或者大模块的分割
# 
# 参数:
#   $1 (字符串): 标题内容文本
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_box_header "系统初始化工具 v1.0"
#   print_box_header "网络配置模块"
# ------------------------------------------------------------------------------
print_box_header() {
    local message=""
    local spaces=2
    local color="${BOLD_CYAN}"
    local icon_val=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--msg|--message) message="$2"; shift 2 ;;
            -s|--spaces)        padding="$2"; shift 2 ;;
            -c|--color)         color="$2"; shift 2 ;;
            -I|--icon)          icon_val="$2"; shift 2 ;;
            *)
                # 兜底逻辑：如果有没加 --前缀的参数，默认追加到消息里
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift 1
                ;;
        esac
    done


    print_line -e "+" -c "=" -C "$color"
    print_echo "$color# ${BOLD}" "$message" "${NC}"
    print_line -e "+" -c "=" -C "$color"
}

# ------------------------------------------------------------------------------
# 函数名: print_box_header_tip
# 功能:   打印一个醒目的黄色小标题或提示信息，带有 # 前缀
#         常用于主标题下方的补充说明，或者二级分类标题
# 
# 参数:
#   $1 (字符串): 提示内容文本
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_box_header_tip "请按键盘方向键选择（空格选中）"
#   print_box_header_tip "注意：此操作不可逆"
# ------------------------------------------------------------------------------
print_box_header_tip() {
    local tip
    tip="$1"

    print_echo "${BOLD_YELLOW}# ${tip}${NC}"
}

# ******************************************************************************
# 全局变量：用于跟踪当前行 ID
# 提供: print_menu_item、print_menu_item_done 使用
# ******************************************************************************
G_LAST_MENU_ROW="-1"

# ------------------------------------------------------------------------------
# 函数名: print_menu_item
# 功能:   通用的菜单项渲染函数，支持“垂直列表”和“流式网格”两种模式。
#
# 模式切换:
#   1. 列表模式 (默认): 不传 -r 参数。每项占一行，支持 -w 参数对齐编号。
#   2. 网格模式 (流式): 传 -r 参数。需配合全局变量 G_LAST_MENU_ROW，多项同行显示。
#
# 参数:
#   -i | --index   (字符串): 菜单编号 (必填)
#   -m | --msg     (字符串): 菜单文本 (必填)
#   -r | --row     (字符串): [网格模式专用] 行标识符。若存在，则启用流式布局
#   -p | --padding (整数)  : 左侧缩进空格数 (列表模式默认0，网格模式根据布局设置)
#   -w | --width   (整数)  : [列表模式专用] 编号区域对齐宽度，默认0(不开启对齐计算)
#   -s | --space   (整数)  : 编号与文本之间的固定空格数 (仅当 -w 为 0 时生效)，默认为 1
#   -I | --icon    (字符串): 后缀图标/标签 (支持 star, hot, new 或自定义)
#   -n | --newline (开关)  : [网格模式专用] 强制在末尾换行 (极少使用，通常由 -r 控制)
#   $1             (字符串): (兜底) 文本内容
#
# 返回值:
#   (无返回值) - 直接输出格式化后的字符串
# 
# 示例:
#   # 场景1: 普通列表
#   print_menu_item -i 1 -m "安装 Docker" -w 2
#
#   # 场景2: 一行两列 (原 print_menu_item)
#   G_LAST_MENU_ROW="-1"
#   print_menu_item -r 1 -p 0 -i 1 -m "开始"
#   print_menu_item -r 1 -p 4 -i 2 -m "停止"
# ------------------------------------------------------------------------------
print_menu_item() {
    local row_id=""
    local padding=0
    local index=""
    local text=""
    local max_width=0    # 编号对齐宽度
    local space_count=1  # 编号与文本间距
    local icon_val=""
    local force_newline=false
    local suffix_space=1 # 默认文本和图标中间空 1 格
    local text_target_width=0 # 文本区域目标宽度 (0表示不启用对齐)

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -r|--row)           row_id="$2"; shift 2 ;;
            -p|--padding)      padding="$2"; shift 2 ;;
            -i|--index)        index="$2"; shift 2 ;;
            -w|--width)        max_width="$2"; shift 2 ;;
            -m|--msg)          text="$2"; shift 2 ;;
            -I|--icon)         icon_val="$2"; shift 2 ;;
            -s|--space)        space_count="$2"; shift 2 ;;
            -n|--newline)      force_newline=true; shift 1 ;;
            -S|--suffix-space) suffix_space="$2"; shift 2 ;;
            -T|--text-width)   text_target_width="$2"; shift 2 ;;
            *)
                # 兜底逻辑
                if [[ -z "$text" ]]; then
                    text="$1"
                else
                    text="$text $1"
                fi
                shift 1
                ;;
        esac
    done

    # 1. [网格模式] 自动换行前置逻辑
    # 只有指定了 row_id 时，才进行行状态检查
    if [[ -n "$row_id" ]]; then
        if [[ "$row_id" != "$G_LAST_MENU_ROW" ]]; then
            [[ "$G_LAST_MENU_ROW" != "-1" ]] && echo ""
            G_LAST_MENU_ROW="$row_id"
        fi
    fi

    # 2. 渲染左侧整体缩进 (Padding)
    [[ "$padding" -gt 0 ]] && printf "%*s" "$padding" ""

    # 3. 计算编号与文本中间的间隔 (Spacer)
    local spacer=""
    if [[ "$max_width" -gt 0 ]]; then
        local index_len=${#index}
        local pad
        (( pad = max_width - index_len + 1 ))
        [[ $pad -lt 1 ]] && pad=1
        printf -v spacer '%*s' "$pad" ''
    else
        # 简单空格
        printf -v spacer '%*s' "$space_count" ''
    fi

    # 4. 计算文本后的填充 (Text Padding)
    local text_padding_str=""
    
    if [[ "$text_target_width" -gt 0 ]]; then
        # 策略A：启用对齐 (计算中文字宽)
        local char_len=${#text}
        local byte_len=$(printf "%s" "$text" | wc -c)
        # 视觉宽度 ≈ 字符数 + (字节数 - 字符数) / 2
        local v_len=$(( char_len + (byte_len - char_len) / 2 ))
        
        local fill_len
        (( fill_len = text_target_width - v_len ))
        [[ $fill_len -lt 1 ]] && fill_len=1 # 至少保留1个空格
        
        printf -v text_padding_str '%*s' "$fill_len" ''
    else
        # 策略B：不启用对齐，直接使用 -S 指定的空格数
        printf -v text_padding_str '%*s' "$suffix_space" ''
    fi

   # 5. 处理图标
    local suffix=""
    if [[ -n "$icon_val" ]]; then
        case "$icon_val" in
            star|default) suffix="${BOLD_YELLOW}${ICON_STAR}${NC}" ;;
            hot)          suffix="${BOLD_RED}[HOT]${NC}" ;;
            new)          suffix="${BOLD_GREEN}[NEW]${NC}" ;;
            *)            suffix="${icon_val}" ;;
        esac
    fi

    # 6. 最终拼接输出
    # 结构: [编号][间隔][文本][文本填充][图标]
    # 注意：text_padding_str 放在文本和图标中间
    local final_content="${BOLD_CYAN}${index}.${NC}${spacer}${text}${text_padding_str}${suffix}${NC}"

    if [[ -n "$row_id" ]] && [[ "$force_newline" == "false" ]]; then
        print_echo -n "$final_content"
    else
        print_echo "$final_content"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: print_menu_item_done
# 功能:   强制重置行状态 (通常用于菜单结束后) 与 print_menu_item 配套使用
#
# 参数:
#   -n | --no-newline | --compact  (开关): 不打印空行 (紧凑模式)
#
# 返回值: 
#   1 - 全局变量：用于跟踪当前行 ID
# 
# 示例:
#   print_menu_item_done
# ------------------------------------------------------------------------------
# shellcheck disable=SC2120
print_menu_item_done() {
    local print_blank_line=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--no-newline|--compact)
                print_blank_line=false
                shift 1
                ;;
            *)
                shift 1
                ;;
        esac
    done

    if [[ "$print_blank_line" == "true" ]]; then
        print_blank
    fi

    G_LAST_MENU_ROW="-1"
}

# ------------------------------------------------------------------------------
# 函数名: print_menu_go_level
# 功能:   菜单层级跳转提示
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   print_menu_go_level
# ------------------------------------------------------------------------------
print_menu_go_level() {
    print_line -c "=" -C "$BOLD_CYAN"

    print_menu_item -r 99 -p 0 -i 0 -m "返回上级菜单" -s 2

    print_menu_item_done

    print_line -c "=" -C "$BOLD_CYAN"
}

# ------------------------------------------------------------------------------
# 函数名: print_key_value
# 功能:   打印对齐的 "键: 值" 格式信息，自动计算中英文混合宽度的对齐
#         常用于显示配置列表、系统信息等
# 
# 参数:
#   -k | --key | --label (字符串): 标签名称 (冒号左边的内容) (必填)
#   -v | --val | --value (字符串): 展示的内容 (冒号右边的内容) (必填)
#   -w | --width         (整数)  : 对齐宽度 (控制值从第几列开始显示)，默认为 15 (可选)
#   -C | --color         (变量)  : 标签颜色，默认为 "${BOLD_CYAN}" (可选)
#   $1, $2               (字符串): (兜底) 若不使用 Flag，分别视为 Key 和 Value
# 
# 返回值:
#   0 - 成功打印
# 
# 示例:
#   print_key_value -k "系统版本" -v "Ubuntu 22.04"
#   print_key_value -k "IP地址" -v "192.168.1.1" -w 20
#   print_key_value "状态" "运行中"  (简写模式)
# ------------------------------------------------------------------------------
print_key_value() {
    # 1. 初始化变量
    local key=""
    local value=""
    local width=15             # 默认对齐宽度
    local color="${BOLD_CYAN}" # 默认标签颜色

    # 2. 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -k|--key|--label)
                key="$2"
                shift 2
                ;;
            -v|--val|--value)
                value="$2"
                shift 2
                ;;
            -w|--width)
                width="$2"
                shift 2
                ;;
            -C|--color)
                color="$2"
                shift 2
                ;;
            *)
                # 兜底逻辑: 
                # 第一个未知参数视为 Key
                # 第二个未知参数视为 Value
                if [[ -z "$key" ]]; then
                    key="$1"
                elif [[ -z "$value" ]]; then
                    value="$1"
                fi
                shift 1
                ;;
        esac
    done

    # 视觉宽度计算 (核心逻辑)
    # 目标：解决中文字符占位宽，但 wc -c 计算字节多的问题
    # 算法：视觉宽度 ≈ 字符数 + (总字节数 - 字符数) / 2
    local char_len=${#key}
    local byte_len
    byte_len=$(printf "%s" "$key" | wc -c)
    
    local key_visual_width
    (( key_visual_width = char_len + (byte_len - char_len) / 2 ))

    # 计算补齐空格
    # pad = 目标宽度 - 当前标签视觉宽度
    local pad
    (( pad = width - key_visual_width ))
    
    # 防止负数 (标签超长时，只给1个空格)
    if [[ $pad -lt 0 ]]; then pad=0; fi

    local spaces
    printf -v spaces '%*s' "$pad" ''

    # 输出
    # 格式: [颜色][Key]:[空格][白色Value]
    # 注意: 这里冒号紧跟在 Key 后面，空格在冒号后面，这样 Value 会左对齐
    print_echo "${color}${key}:${spaces}${BOLD_WHITE}${value}${NC}"
}