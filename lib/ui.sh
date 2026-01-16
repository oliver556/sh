#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - UI 输出与界面渲染工具
#
# @文件路径: lib/ui.sh
# @功能描述: 负责 “画” (UI 渲染、菜单项、颜色、间距)
# 
# 设计原则：
# - 只负责“显示”和“输入”
# - 不包含任何业务逻辑
# - 不做任何系统操作
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-31
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: ui
# 功能:   综合打印封装函数 (分发器模式)
# 
# 参数:
#   $1 (number): 链式调用时所输入的值
# 
# 返回值: 执行对应功能
# 
# 示例:
#   ui echo "$1"
# ------------------------------------------------------------------------------
ui() {
    local action="$1"
    shift # 弹出第一个参数 (如 "print", "clean", "echo" 等)

    case "$action" in
        # ------------------------------
        # 基础输出 (内外统一调用)
        # ------------------------------
        "echo")
        # 统一 echo 输出，确保支持转义字符
        if [[ "$1" == "-n" ]]; then
            shift
            echo -ne "$*"
        else
            echo -e "$*"
         fi
        ;;

        # ------------------------------
        # 输出一个空行
        # ------------------------------
        "blank")
            ui echo ""
            ;;

        # ------------------------------
        # 分隔线与边框，用于分隔内容
        # ------------------------------
        
        # 样式 1 默认/通用横线 (对应 ui_tip / 普通分隔) -> 推荐用 青色或淡灰，不要太抢眼
        "line" | "line_tip" | "line_reload")
            ui echo "${BOLD_CYAN}──────────────────────────────────────────────────────────────${NC}"
            ;;

        # 信息横线 (对应 ui_info) -> 蓝色
        "line_info")
            ui echo "${BOLD_BLUE}──────────────────────────────────────────────────────────────${NC}"
            ;;

        # 成功横线 (对应 ui_success) -> 绿色
        "line_success")
            ui echo "${BOLD_GREEN}──────────────────────────────────────────────────────────────${NC}"
            ;;

        # 警告横线 (对应 ui_warn) -> 黄色
        "line_warn")
            ui echo "${BOLD_YELLOW}──────────────────────────────────────────────────────────────${NC}"
            ;;

        # 错误横线 (对应 ui_error) -> 红色
        "line_error")
            ui echo "${BOLD_RED}──────────────────────────────────────────────────────────────${NC}"
            ;;
        
        "line_2")
            # 样式 2
            ui echo  ${BOLD_CYAN}"--------------------------------------------------------------"${NC}
            ;;

        "line_3")
            # 样式 3
            ui echo ${BOLD_RED}"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"${NC}
            ;;

        # 样式 4（顶部边框）
         "border_top")
            ui echo  ${BOLD_CYAN}"+============================================================+"${NC}
            ;;

        # 样式 5（底部边框）
        "border_bottom")
            ui echo ${BOLD_CYAN}"=============================================================="${NC}
            ;;

        # ------------------------------
        # 页面打印
        # ------------------------------
        "print")
            local action2="$1" # 此时 $1 是原来的 $2 (如 "tip")
            shift # 弹出第二个参数

            case "$action2" in
                # ------------------------------
                # 首页 / 门户页
                # ------------------------------
                "home_header")
                    # 参数 1: 标题文字
                    local title="$1"

                    ui border_top

                    ui echo "${BOLD_CYAN}#${BOLD}$(printf "$title")${NC}"

                    ui border_top
                    ;;

                # ------------------------------
                # 详情页 / 信息展示顶部
                # ------------------------------
                "page_header")
                    local title="$1"

                    # 内容区固定宽度（和 ui border_top 对齐）
                    local content_width=60

                    ui border_top

                    # 计算标题的显示宽度（而不是字符长度）
                    local title_width
                    title_width=$(ui_str_width "$title")

                    # 右侧需要补的空格数
                    local pad=$((content_width - 2 - title_width))
                    ((pad < 0)) && pad=0

                    printf "${BOLD_CYAN}# %s%*s\n" \
                        "${BOLD_CYAN}${title}${NC}" \
                        "$pad" ""

                    ui border_top
                    ;;

                # ------------------------------
                # 首页 / 提示行
                # ------------------------------
                "tip")
                    # 此时 $1 是原来的 $3 (提示文字内容)
                    local tip="$1"
                    ui echo "${BOLD_YELLOW}#$(printf "$tip")${NC}"
                    ;;

                *)
                    ui_warn_menu "无效选项，请重新输入..."
                    ;;
            esac
            ;;

        # ------------------------------
        # 页面清屏
        # ------------------------------
        "clear")
            clear
            ;;

        # ------------------------------
        # 菜单项渲染
        # ------------------------------
        "item")
            local index="$1"
            local text="$2"

            # 最大编号长度（如主菜单最大是 99，则 max_index_len=2）
            local max_index_len=2

            # 当前编号长度
            local index_len=${#index}

            # 空格数量 = 最大编号长度 - 当前编号长度 + 1 (1 表示编号后至少一个空格)
            local pad=$((max_index_len - index_len + 1))
            local spaces=$(printf '%*s' "$pad" '')

            # 输出菜单
            ui echo "${CYAN}${index}.${spaces}${NC}${text}${NC}"
            ;;

        # ------------------------------
        # 展示列表
        # ------------------------------

        "item_list")
            # 参数 1：标签名称 (Label)
            # 参数 2：对齐宽度 / 冒号后的空格数 (默认 15)
            # 参数 3：展示的内容 (Value)
            local label="$1"
            local width="${2:-15}"
            local value="$3"

            # 更加健壮的显示宽度计算方式 (支持 UTF-8 中英文混排)
            # 获取字符数
            local char_len=${#label}
            # 获取字节数
            local byte_len=$(printf "%s" "$label" | wc -c)

            # 视觉宽度算法：字符数 + (字节数 - 字符数) / 2
            # 中文字符占 3 字节，字符数 1，计算结果为 1 + (3-1)/2 = 2
            local label_w=$(( char_len + (byte_len - char_len) / 2 ))

            # 计算需要补全的空格数 (目标宽度 - 标签实际宽度)
            local pad=$((width - label_w))
            ((pad < 0)) && pad=0
            local spaces=$(printf '%*s' "$pad" '')

            # 统一输出格式：标签(青色):[空格补齐]内容(白色)
            ui echo "${BOLD_CYAN}${label}:${spaces}${BOLD_WHITE}${value}${NC}"
            ;;

        *)
            ui_warn_menu "无效选项，请重新输入..."
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: ui_str_width
# 功能:   计算字符串在终端中的显示宽度 (中2英1)
# 
# 参数:
#   $1 (string): 要显示的文本 (必填)
#   $2 ([类型]): [描述参数2的含义]
# 
# 返回值: 计算字符串在终端中的显示宽度
# 
# 示例:
#   ui_str_width "$1"
# ------------------------------------------------------------------------------
# 
ui_str_width() {
    local str="$1"
    local width=0
    local char

    # 按字符拆分
    while IFS= read -r -n1 char; do
        # 如果是 ASCII，宽度 +1，否则 +2
        # if [[ "$char" =~ [[:ascii:]] ]]; then
        if [[ "$char" =~ [\x00-\x7f] ]]; then
            ((width+=1))
        else
            ((width+=2))
        fi
    done <<< "$str"

    echo "$width"
}

# ******************************************************************************
# 状态反馈 (一般用于执行各种自动化时的内容输出做切割)
# ******************************************************************************
log_info() {
    ui echo "${ON_GREEN}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

log_warn() {
    ui echo "${ON_YELLOW}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

log_error() {
    ui echo "${ON_RED}${BOLD_WHITE} INFO ${NC} ${BOLD_WHITE}$1${NC}";
}

# ******************************************************************************
# 状态反馈
# ******************************************************************************
# 纯文本输出（最低级）
ui_text() {
    ui echo "$1"
}
# 用户提示 / 说明（加粗白）-> 用箭头引导
ui_tip() {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_WHITE}➜$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_WHITE}➜$(ui_spaces 1)${text}${NC}"
    fi
}
# 搜索提示
ui_search() {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_CYAN}⌕$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_CYAN}⌕$(ui_spaces 1)${text}${NC}"
    fi
}
# 信息提示（中性状态）-> 用实心圆点
ui_info()  {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_BLUE}●$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_BLUE}●$(ui_spaces 1)${text}${NC}"
    fi
}
# 成功提示(绿) -> 经典的对号
ui_success() {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_GREEN}✔$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_GREEN}✔$(ui_spaces 1)${text}${NC}"
    fi
}
# 警告提示（非致命）(黄) -> 叹号
ui_warn()  {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_YELLOW}▲$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_YELLOW}▲$(ui_spaces 1)${text}${NC}"
    fi
}
# 错误提示（致命）(红) -> 经典的叉号
ui_error() {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_RED}✘$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_RED}✘$(ui_spaces 1)${text}${NC}"
    fi
}
# 菜单选项错误（非致命）
ui_warn_menu()  {
    local text="$1"
    local extra="${2:-}"

    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_YELLOW}✘$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_YELLOW}✘$(ui_spaces 1)${text}${NC}"
    fi
}
# 重载/刷新/处理中 (青色)
# 使用符号: ⟳
ui_reload() {
    local text="$1"
    local extra="${2:-}"
    
    # 颜色建议用 CYAN (青色) 代表过程/网络/刷新
    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_CYAN}⟳$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_CYAN}⟳$(ui_spaces 1)${text}${NC}"
    fi
}

# 优化 / 加速 / 性能提升
# 使用符号: ⚡
ui_speed() {
    local text="$1"
    local extra="${2:-}"
    
    # BOLD_MAGENTA (紫) 或 BOLD_YELLOW (黄) 都很有速度感
    if [[ -n "$extra" ]]; then
        ui echo "${BOLD_MAGENTA}⚡$(ui_spaces 1)${text} ${extra}${NC}"
    else
        ui echo "${BOLD_MAGENTA}⚡$(ui_spaces 1)${text}${NC}"
    fi
}

# ==============================================================================
# 盒式反馈 (带上下边框的强调模式)
# ==============================================================================
# 成功 - 盒式
ui_box_success() {
    local text="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"
    
    local padding=""
    local next_arg="$arg2"

    # -----------------------------------------------------------
    # 判断 padding (方位) 是哪个参数
    # -----------------------------------------------------------
    
    # 优先检查第3个参数 (标准写法: 文本, 内容, 方位)
    if [[ "$arg3" == "top" || "$arg3" == "bottom" || "$arg3" == "both" || "$arg3" == "all" ]]; then
        padding="$arg3"
    
    # 如果第3个没传，检查第2个参数是否为方位词 (偷懒写法: 文本, 方位)
    elif [[ "$arg2" == "top" || "$arg2" == "bottom" || "$arg2" == "both" || "$arg2" == "all" ]]; then
        padding="$arg2"
        next_arg="" # 既然 arg2 被识别为方位控制，那就把它从内容里清空，防止被打印出来
    fi

    # -----------------------------------------------------------
    # 执行输出
    # -----------------------------------------------------------
    
    # 【顶部空行】
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi

    ui line_success
    
    # 透传 next_arg (可能是空，可能是自定义内容)
    if [[ -n "$next_arg" ]]; then
        ui_success "$text" "$next_arg"
    else
        ui_success "$text"
    fi

    ui line_success

    # 【底部空行】
    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi
}

# 错误 - 盒式 (常用于脚本出错退出前)
ui_box_error() {
    local text="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"
    
    local padding=""
    local next_arg="$arg2"

    # -----------------------------------------------------------
    # 判断 padding (方位) 是哪个参数
    # -----------------------------------------------------------
    
    # 优先检查第3个参数 (标准写法: 文本, 内容, 方位)
    if [[ "$arg3" == "top" || "$arg3" == "bottom" || "$arg3" == "both" || "$arg3" == "all" ]]; then
        padding="$arg3"
    
    # 如果第3个没传，检查第2个参数是否为方位词 (偷懒写法: 文本, 方位)
    elif [[ "$arg2" == "top" || "$arg2" == "bottom" || "$arg2" == "both" || "$arg2" == "all" ]]; then
        padding="$arg2"
        next_arg="" # 既然 arg2 被识别为方位控制，那就把它从内容里清空，防止被打印出来
    fi

    # -----------------------------------------------------------
    # 执行输出
    # -----------------------------------------------------------
    
    # 【顶部空行】
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi

    ui line_error
    
    # 透传 next_arg (可能是空，可能是自定义内容)
    if [[ -n "$next_arg" ]]; then
        ui_error "$text" "$next_arg"
    else
        ui_error "$text"
    fi

    ui line_error

    # 【底部空行】
    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi
}

# 警告 - 盒式 (重要注意事项)
ui_box_warn() {
    local text="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"
    
    local padding=""
    local next_arg="$arg2"

    # -----------------------------------------------------------
    # 判断 padding (方位) 是哪个参数
    # -----------------------------------------------------------
    
    # 优先检查第3个参数 (标准写法: 文本, 内容, 方位)
    if [[ "$arg3" == "top" || "$arg3" == "bottom" || "$arg3" == "both" || "$arg3" == "all" ]]; then
        padding="$arg3"
    
    # 如果第3个没传，检查第2个参数是否为方位词 (偷懒写法: 文本, 方位)
    elif [[ "$arg2" == "top" || "$arg2" == "bottom" || "$arg2" == "both" || "$arg2" == "all" ]]; then
        padding="$arg2"
        next_arg="" # 既然 arg2 被识别为方位控制，那就把它从内容里清空，防止被打印出来
    fi

    # -----------------------------------------------------------
    # 执行输出
    # -----------------------------------------------------------
    
    # 【顶部空行】
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi

    ui line_warn
    
    # 透传 next_arg (可能是空，可能是自定义内容)
    if [[ -n "$next_arg" ]]; then
        ui_warn "$text" "$next_arg"
    else
        ui_warn "$text"
    fi

    ui line_warn

    # 【底部空行】
    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi
}

# ==============================================================================
# 盒式信息反馈函数 (ui_box_info)
#
# 支持三种调用方式：
# 1. ui_box_info "文本" "自定义后缀" "bottom"  -> 显示后缀 + 底部空行
# 2. ui_box_info "文本" "bottom"             -> 无后缀 + 底部空行 (智能识别)
# 3. ui_box_info "文本" "自定义后缀"           -> 显示后缀 + 无空行
# ==============================================================================
ui_box_info() {
    local text="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"
    
    local padding=""
    local next_arg="$arg2"

    # -----------------------------------------------------------
    # 判断 padding (方位) 是哪个参数
    # -----------------------------------------------------------
    
    # 优先检查第3个参数 (标准写法: 文本, 内容, 方位)
    if [[ "$arg3" == "top" || "$arg3" == "bottom" || "$arg3" == "both" || "$arg3" == "all" ]]; then
        padding="$arg3"
    
    # 如果第3个没传，检查第2个参数是否为方位词 (偷懒写法: 文本, 方位)
    elif [[ "$arg2" == "top" || "$arg2" == "bottom" || "$arg2" == "both" || "$arg2" == "all" ]]; then
        padding="$arg2"
        next_arg="" # 既然 arg2 被识别为方位控制，那就把它从内容里清空，防止被打印出来
    fi

    # -----------------------------------------------------------
    # 执行输出
    # -----------------------------------------------------------
    
    # 【顶部空行】
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi

    ui line_info
    
    # 透传 next_arg (可能是空，可能是自定义内容)
    if [[ -n "$next_arg" ]]; then
        ui_info "$text" "$next_arg"
    else
        ui_info "$text"
    fi

    ui line_info

    # 【底部空行】
    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi
}

# 重载/刷新/处理中 - 盒式
ui_box_warn() {
    local text="$1"
    local arg2="${2:-}"
    local arg3="${3:-}"
    
    local padding=""
    local next_arg="$arg2"

    # -----------------------------------------------------------
    # 判断 padding (方位) 是哪个参数
    # -----------------------------------------------------------
    
    # 优先检查第3个参数 (标准写法: 文本, 内容, 方位)
    if [[ "$arg3" == "top" || "$arg3" == "bottom" || "$arg3" == "both" || "$arg3" == "all" ]]; then
        padding="$arg3"
    
    # 如果第3个没传，检查第2个参数是否为方位词 (偷懒写法: 文本, 方位)
    elif [[ "$arg2" == "top" || "$arg2" == "bottom" || "$arg2" == "both" || "$arg2" == "all" ]]; then
        padding="$arg2"
        next_arg="" # 既然 arg2 被识别为方位控制，那就把它从内容里清空，防止被打印出来
    fi

    # -----------------------------------------------------------
    # 执行输出
    # -----------------------------------------------------------
    
    # 【顶部空行】
    if [[ "$padding" == "top" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi

    ui line_warn
    
    # 透传 next_arg (可能是空，可能是自定义内容)
    if [[ -n "$next_arg" ]]; then
        ui_reload "$text" "$next_arg"
    else
        ui_reload "$text"
    fi

    ui line_reload

    # 【底部空行】
    if [[ "$padding" == "bottom" || "$padding" == "both" || "$padding" == "all" ]]; then
        ui blank
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ui_exit
# 功能:   输出告别语并退出脚本
# 
# 参数: 无
# 
# 返回值: 排列好的结束语
# 
# 示例:
#   ui_exit
# ------------------------------------------------------------------------------
ui_exit() {
    ui clear
    ui line
    ui echo "${BOLD_GREEN}■$(ui_spaces 1)感谢使用 VpsScriptKit！${NC}"
    ui echo "${BOLD_CYAN}■$(ui_spaces 1)江湖有缘再见。${NC}"
    ui line
    sleep 1
    ui clear
    exit 0
}

# ******************************************************************************
# 全局变量：用于跟踪当前行 ID
# 提供：ui_menu_item、ui_menu_done 使用
# ******************************************************************************
G_LAST_MENU_ROW=-1

# ------------------------------------------------------------------------------
# 函数名: ui_menu_item
# 功能:   菜单项渲染 (流式行控布局)
# 
# 参数:
#   $1 (string): 行标识符 (相同则不换行) (必填)
#   $2 (string): 距离左侧或前一个项的间距 (必填)
#   $3 (string): 菜单编号 (必填)
#   $4 (string): 菜单文本 (必填)
#   $5 (string): 编号后的间距 (可选)
# 
# 返回值: 选然后的排版
# 
# 示例:
#   ui_menu_item $1 $2 $3 $4 $5
# ------------------------------------------------------------------------------
ui_menu_item() {
    local row_id="$1"
    local padding="$2"
    local index="$3"
    local text="$4"
    local space_count="${5:-1}"

    # 自动换行逻辑：如果 row_id 变化，则输出换行符
    if [[ "$row_id" != "$G_LAST_MENU_ROW" ]]; then
        # 如果不是第一次调用，则换行
        if [[ "$G_LAST_MENU_ROW" != "-1" ]]; then
            echo ""
        fi
        G_LAST_MENU_ROW="$row_id"
    fi

    # 渲染间距 (Padding)
    printf "%*s" "$padding" ""

    # 渲染菜单内容
    # 格式: 编号. 文本
    ui echo -n "${BOLD_CYAN}${index}.${NC}$(ui_spaces $space_count)${text}${NC}"
}

# ------------------------------------------------------------------------------
# 函数名: ui_menu_done
# 功能:   强制重置行状态 (通常用于菜单结束后) 与 ui_menu_item 配套使用
# 
# 参数: 无
# 
# 返回值: 
#   1 - 全局变量：用于跟踪当前行 ID
# 
# 示例:
#   ui_menu_done
# ------------------------------------------------------------------------------
ui_menu_done() {
    ui blank
    G_LAST_MENU_ROW=-1
}

# ------------------------------------------------------------------------------
# 函数名: ui_go_level
# 功能:   菜单层级跳转提示
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   ui_go_level
# ------------------------------------------------------------------------------
ui_go_level() {
    ui border_bottom

    ui_menu_item 99 0 0 "返回上级菜单" 2

    ui_menu_done

    ui border_bottom
}