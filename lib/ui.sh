#!/usr/bin/env bash

### ============================================================
# VpsScriptKit - UI 输出与界面渲染工具 - 函数库
# @名称:         ui.sh
# @职责:
# 1. 定义统一的终端输出样式
# 2. 渲染主菜单 / 子菜单
# 3. 提供标准化输入提示
#
# 设计原则：
# - 只负责“显示”和“输入”
# - 不包含任何业务逻辑
# - 不做任何系统操作
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2025-12-31
# @修改日期:     2025-01-04
#
# @许可证:       MIT
### ============================================================

# ------------------------------
# 引入颜色库
# ------------------------------
source "${BASE_DIR}/lib/color.sh"

# ------------------------------
# 综合打印封装函数 (分发器模式)
# ------------------------------
ui() {
  local action="$1"
  shift # 弹出第一个参数 (如 "print", "clean", "echo" 等)

  case "$action" in
    # ------------------------------
    # 分隔线与边框
    # ------------------------------

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

    "blank")
      # 输出一个空行
      ui echo ""
    ;;

    # ------------------------------
    # 分隔线与边框
    # ------------------------------
    "line")
      # 输出一条横线，用于分隔内容
      ui echo  ${LIGHT_CYAN}"──────────────────────────────────────────────────────────────"${RESET}
    ;;

    "line_2")
      # 输出一条横线，用于分隔内容
      ui echo  ${LIGHT_CYAN}"--------------------------------------------------------------"${RESET}
    ;;

    "border_top")
      # 输出顶部边框
      ui echo  ${LIGHT_CYAN}"+============================================================+"${RESET}
    ;;

    "border_bottom")
      # 输出底部边框
      ui echo ${LIGHT_CYAN}"=============================================================="${RESET}
    ;;

    # ------------------------------
    # 页面打印
    # ------------------------------
    "print")
      local action2="$1" # 此时 $1 是原来的 $2 (如 "tip")
      shift # 弹出第二个参数

      case "$action2" in
        # 首页 / 门户页
        "home_header")
          # 参数 1：标题文字
          local title="$1"

          ui border_top
          # 输出顶部边框

          ui echo "${LIGHT_CYAN}#${BOLD}$(printf '%60s' "$title")${RESET}     ${LIGHT_CYAN}#${RESET}"
          # 居中显示标题（简单方式，保证对齐感）

          ui border_top
          # 再输出一次边框，形成包裹感
        ;;

        # 功能页 / 子菜单页
        "page_header")
          # 参数 1：页面标题
          local title="$1"

          ui border_top

          # 从左开始输出，不居中
          ui echo "# ${LIGHT_CYAN}${BOLD}${title}${RESET}"

          ui border_top
        ;;

        # 查询 / 信息展示页顶部
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

        # 详情页 / 信息展示顶部 (未开发)
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

        # 首页 / 提示行
        "tip")
          # 此时 $1 是原来的 $3 (提示文字内容)
          local tip="$1"
          ui echo "${LIGHT_YELLOW}#$(printf '%60s' "💡  Tip: $tip")${RESET}              ${LIGHT_YELLOW}#${RESET}"
        ;;


        *)
          ui echo "${RED}未知打印指令: $action2${RESET}"
        ;;
      esac
    ;;

    # ------------------------------
    # 用户输入提示
    # ------------------------------
    "prompt")
      # 参数 1：提示文字
      local prompt="$1"

      ui echo -n ${BOLD_LIGHT_CYAN}"👉 ${prompt}: "${RESET}
      # 输出提示符，不换行
    ;;

    "read_choice")
      # 从标准输入读取用户输入
      local choice

      read -r choice
      # 使用 read -r，避免反斜杠被转义

      echo "$choice"
      # 将读取到的内容输出，供调用方接收
    ;;

    # 展示页用（status / info）
    "wait_return")
      ui blank
      ui blank
      ui echo "${LIGHT_GREEN}执行完成${RESET}"
      ui echo "${LIGHT_WHITE}按回车键返回...${RESET}"

      # -s: 静默模式，不回显输入
      # -r: 允许反斜杠
      read -s -r
    ;;

    # ------------------------------
    # 页面清屏
    # ------------------------------
    "clear")
        # 清屏操作
        clear
    ;;
    
    # ------------------------------
    # 状态信息输出
    # ------------------------------
    "info")
      # 普通信息提示
      ui echo "${GREEN}✔${RESET} $1"
    ;;

    "warn")
      # 普通信息提示
      ui echo "${YELLOW}⚠${RESET} $1"
    ;;

    "error")
      # 错误提示
      ui echo "${GREEN}✔${RESET} $1"
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
      ui echo "${LIGHT_CYAN}${index}.${spaces}${RESET}${LIGHT_WHITE}${text} ▶${RESET}"
    ;;

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
      ui echo "${RED}未知 UI 指令: $action${RESET}"
    ;;
  esac
}

# ------------------------------
# 主菜单渲染
# ------------------------------

ui_main_menu() {
  # 显示主菜单界面 (菜单内容本身不包含逻辑，只是展示)
  ui line

  # 系统工具菜单项
  ui item 1 "系统工具"

  # 基础工具菜单项
  ui item 2 "${BOLD_GREY}基础工具${RESET}"

  # 进阶工具菜单项
  ui item 3 "${BOLD_GREY}进阶工具${RESET}"

  # Docker 管理菜单项
  ui item 4 "${BOLD_GREY}Docker 管理${RESET}"

  ui line

  # 测试脚本合集菜单项
  ui item 8 "${BOLD_GREY}测试脚本合集${RESET}"

  # 节点搭建脚本菜单项
  ui item 9 "${BOLD_GREY}节点搭建脚本${RESET}"

  ui line

  ui item 99 "${BOLD_GREY}脚本工具${RESET}"

  # 脚本工具菜单项

  ui border_bottom

  # 退出选项
  ui item 0 "退出程序"

  ui border_bottom
}

# ------------------------------
# 工具函数 (独立保留，用于数值计算)
# ------------------------------

# 计算字符串在终端中的显示宽度 (中2英1)
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

# 右侧补全工具
ui_pad_right() {
  local str="$1"
  local target_width="$2"

  local str_width
  str_width=$(ui_str_width "$str")

  local pad=$((target_width - str_width))
  ((pad < 0)) && pad=0

  printf "%s%*s" "$str" "$pad" ""
}

# ------------------------------
# 全局变量：用于跟踪当前行 ID
# ------------------------------
G_LAST_MENU_ROW=-1

# ------------------------------
# 菜单项渲染 (流式行控布局)
# ------------------------------
# 参数1: row_id  - 行标识符 (相同则不换行)
# 参数2: padding - 距离左侧或前一个项的间距
# 参数3: index   - 菜单编号
# 参数4: text    - 菜单文本
ui_menu_item() {
  local row_id="$1"
  local padding="$2"
  local index="$3"
  local text="$4"

  # 1. 自动换行逻辑：如果 row_id 变化，则输出换行符
  if [[ "$row_id" != "$G_LAST_MENU_ROW" ]]; then
    # 如果不是第一次调用，则换行
    if [[ "$G_LAST_MENU_ROW" != "-1" ]]; then
      echo ""
    fi
    G_LAST_MENU_ROW="$row_id"
  fi

  # 2. 渲染间距 (Padding)
  printf "%*s" "$padding" ""

  # 3. 渲染菜单内容
  # 格式: 编号. 文本 ▶
  echo -ne "${LIGHT_CYAN}${index}.${RESET} ${LIGHT_WHITE}${text} ${LIGHT_CYAN}${RESET}"
}

# ------------------------------
# 强制重置行状态 (通常用于菜单结束后)
# ------------------------------
ui_menu_done() {
  echo ""
  G_LAST_MENU_ROW=-1
}