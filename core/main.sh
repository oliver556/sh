#!/usr/bin/env bash
# 指定使用 bash 解释器执行

# ============================================================
# VpsScriptKit - 主入口
#
# 职责：
# 1. 初始化全局变量
# 2. 加载 UI / 工具 / 路由模块
# 3. 显示主菜单
# 4. 等待用户输入
# ============================================================

# ------------------------------
# 全局变量
# ------------------------------

# 脚本版本
VSK_VERSION="0.0.1"

# 脚本根目录
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"


# 日志目录
VSK_LOG_DIR="$BASE_DIR/logs"
mkdir -p "$VSK_LOG_DIR"

# 加载 OS 识别模块（必须最先）
source "${BASE_DIR}/lib/os.sh"

# 加载 OS 识别
#source "${BASE_DIR}/lib/os.sh"

# 非 Linux 直接提示并退出
# if [[ "$OS_SUPPORTED" != "true" ]]; then
#   echo "❌ 当前系统仅用于开发调试，不支持正式运行"
#   echo "👉 请将本项目部署至 Linux VPS 后执行"
#   exit 1
# fi

# ------------------------------
# 引入库
# ------------------------------

# 引入 - UI 输出与界面渲染工具 - 函数库
source "$BASE_DIR/lib/ui.sh"

# 引入 - 通用工具 - 函数库
source "$BASE_DIR/lib/utils.sh"

# 引入 - 路由模块
source "$BASE_DIR/core/router.sh"

# 引入 系统信息展示
source "${BASE_DIR}/modules/system/status.sh"

# ------------------------------
# 主循环
# ------------------------------

while true; do
  # 清屏
  ui clear

  # 打印顶部标题
  ui print home_header "            🧰  一款全功能的 Linux 管理脚本！    v$VSK_VERSION"

  # 打印提示行
  ui print tip "命令行输入 v 可快速启动脚本"

  # 打印主菜单
  ui_main_menu

  # 提示用户输入
  ui prompt "请输入你的选择"

  # 读取用户输入
  choice="$(ui read_choice)"

  # 调用路由分发
  router_dispatch "$choice"
done
