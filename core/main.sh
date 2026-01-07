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
# 1. 环境初始化
# ------------------------------

# 导出根目录 (如果环境变量没传，则自动计算)
export BASE_DIR="${BASE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# 读取版本号 (从根目录 version 文件读取，方便自动更新同步)
VSK_VERSION=$(cat "$BASE_DIR/version" | xargs)

# 日志与临时目录准备
VSK_LOG_DIR="$BASE_DIR/logs"
mkdir -p "$VSK_LOG_DIR"

# ------------------------------
# 2. 引入依赖库 (顺序敏感)
# ------------------------------

# 基础识别与 UI 库
source "${BASE_DIR}/lib/os.sh"    # OS 识别模块（必须最先）
source "${BASE_DIR}/lib/ui.sh"    # UI 输出与界面渲染工具 - 函数库
source "${BASE_DIR}/lib/utils.sh" # 通用工具 - 函数库

# 功能函数库
source "${BASE_DIR}/lib/check.sh"          # 通用检测工具 - 函数库
source "${BASE_DIR}/lib/network.sh"        # 网络信息工具 - 函数库
source "${BASE_DIR}/lib/system.sh"         # 系统信息工具 - 函数库
source "${BASE_DIR}/lib/validate.sh"       # 能力检测工具 - 函数库
source "${BASE_DIR}/lib/confirm_utils.sh"  # 交互确认工具 - 函数库

# 业务模块与路由
source "${BASE_DIR}/core/router.sh"           # 路由模块

# # ------------------------------
# # 3. 命令行参数预处理
# # ------------------------------
# # 处理通过 bin/v 传入的参数，例如：v --update 或 v --version
# case "${1:-}" in
#     --update|-u)
#         if [[ -f "${BASE_DIR}/update.sh" ]]; then
#             bash "${BASE_DIR}/update.sh"
#             exit 0
#         fi
#         ;;
#     --version|-v)
#         echo "VpsScriptKit Version: $VSK_VERSION"
#         exit 0
#     ;;
# esac

# ------------------------------
# 4. 退出清理 (被动中止) (防止颜色溢出)
# ------------------------------
_cleanup() {
  ui_exit
}
trap _cleanup SIGINT SIGTERM

# ------------------------------
# 5. 主菜单循环
# ------------------------------

main_loop() {
  while true; do
    ui clear

    # 头部渲染
    ui print home_header " 🧰  一款全功能的 Linux 管理脚本！ v$VSK_VERSION"
    ui print tip " 💡 Tip: 命令行输入 v 可快速启动脚本"

    # 主菜单内容 (定义在 lib/ui.sh 中)
    ui_main_menu

    # 读取用户输入
    choice=$(ui_read_choice)

    # 路由分发 (定义在 core/router.sh 中)
    router_dispatch "$choice"
  done
}

main_loop
