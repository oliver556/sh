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
        "line")
            # 样式 1
            ui echo  ${LIGHT_CYAN}"──────────────────────────────────────────────────────────────"${RESET}
            ;;

        "line_2")
            # 样式 2
            ui echo  ${LIGHT_CYAN}"--------------------------------------------------------------"${RESET}
            ;;

        "line_3")
            # 样式 3
            ui echo ${BOLD_RED}"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"${RESET}
            ;;

        # 样式 4（顶部边框）
         "border_top")
            ui echo  ${LIGHT_CYAN}"+============================================================+"${RESET}
            ;;

        # 样式 5（底部边框）
        "border_bottom")
            ui echo ${LIGHT_CYAN}"=============================================================="${RESET}
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

                    ui echo "${LIGHT_CYAN}#${BOLD}$(printf "$title")${RESET}"

                    ui border_top
                    ;;
            
                # ------------------------------
                # 功能页 / 子菜单页
                # ------------------------------
                "page_header")
                    # 参数 1：页面标题
                    local title="$1"

                    ui border_top

                    # 从左开始输出，不居中
                    ui echo "# ${LIGHT_CYAN}${BOLD}${title}${RESET}"

                    ui border_top
                    ;;

                # ------------------------------
                # 查询 / 信息展示页顶部
                # ------------------------------
                "info_header")
                    # 参数 1：信息页标题
                    local title="$1"

                    # 输出顶部边框
                    ui border_top

                    # 用不同的风格输出标题
                    # 例如：绿色 + 加粗 + 左对齐 + 尾部补充横线，区分门户页和子菜单页
                    ui echo "# ${LIGHT_GREEN}${BOLD}${title}${RESET}"

                    # 再输出一次边框
                    ui border_top
                    ;;

                # ------------------------------
                # 详情页 / 信息展示顶部 (未开发)
                # ------------------------------
                "page_header_full")
                    # 参数 1：页面标题
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

                    # 输出标题行（左对齐，右侧自动补空格）
                    printf "# %s%*s\n" \
                        "${LIGHT_CYAN}${BOLD}${title}${RESET}" \
                        "$pad" ""

                    ui border_top
                    ;;

                # ------------------------------
                # 首页 / 提示行
                # ------------------------------
                "tip")
                    # 此时 $1 是原来的 $3 (提示文字内容)
                    local tip="$1"
                    ui echo "${LIGHT_YELLOW}#$(printf "$tip")${RESET}"
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
            ui echo "${LIGHT_CYAN}${index}.${spaces}${RESET}${LIGHT_WHITE}${text}${RESET}"
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
            ui echo "${BOLD_LIGHT_CYAN}${label}:${spaces}${BOLD_LIGHT_WHITE}${value}${RESET}"
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
        if [[ "$char" =~ [[:ascii:]] ]]; then
            ((width+=1))
        else
            ((width+=2))
        fi
    done <<< "$str"

    echo "$width"
}

# ******************************************************************************
# 状态反馈
# ******************************************************************************
# 纯文本输出（最低级）
ui_text() {
    ui echo "$1"
}
# 用户提示 / 说明（加粗白）
ui_tip() {
    ui echo "${BOLD_WHITE}➤$(ui_spaces 1)$1${RESET}"
}
# 信息提示（中性状态）
ui_info()  {
    ui echo "${BLUE}ℹ$(ui_spaces 1)$1${LIGHT_WHITE}"
}
# 成功提示
ui_success() {
    ui echo "${BOLD_GREEN}✔$(ui_spaces 1)$1${LIGHT_WHITE}"
}
# 警告提示（非致命）
ui_warn()  {
    ui echo "${BOLD_YELLOW}⚠$(ui_spaces 1)$1${LIGHT_WHITE}"
}
# 错误提示（致命）
ui_error() {
    ui echo "${BOLD_RED}✘$(ui_spaces 1)$1${LIGHT_WHITE}";
}
# 菜单选项错误（非致命）
ui_warn_menu()  {
    ui echo "${BOLD_YELLOW}❌$(ui_spaces)$1${LIGHT_WHITE}"
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
    ui echo "${BOLD_GREEN}👋$(ui_spaces)感谢使用 VpsScriptKit！${LIGHT_WHITE}"
    ui echo "${BOLD_CYAN}👋$(ui_spaces)江湖有缘再见。${LIGHT_WHITE}"
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
    ui echo -n "${LIGHT_CYAN}${index}.${RESET}$(ui_spaces $space_count)${LIGHT_WHITE}${text}${RESET}"
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