#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 主入口
# 
# @文件路径: main.sh
# @功能描述: 环境初始化、依赖加载、主菜单渲染与路由分发
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-09
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************
# 开启错误调试捕捉：一旦出错，打印行号和错误命令
trap 'echo -e "\033[31m[Error] 脚本异常退出！出错行号: $LINENO，错误命令: $BASH_COMMAND\033[0m"' ERR

set -o errexit   # 一旦有命令返回非 0，立即退出脚本，避免错误被忽略
set -o pipefail  # 管道中任意一段失败，整体失败，防止错误被吞掉
set -o nounset   # 使用未定义变量时直接报错，避免拼写错误导致隐蔽 bug

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************

# 导入环境变量
source "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

# 检测系统是否支持本脚本
# check_supported_os

source "${BASE_DIR}/modules/system/maintain/menu.sh"

# ------------------------------------------------------------------------------
# 函数名: _cleanup
# 功能:  捕捉错误的退出
# 
# 参数: 无
# 
# 返回值:
#   0 - 错误时的信息提示
# 
# 示例:
#   _cleanup
# ------------------------------------------------------------------------------
_cleanup() {
  ui_exit
}
trap _cleanup SIGINT SIGTERM

# ------------------------------------------------------------------------------
# 函数名: 脚本主菜单
# 功能:   提供脚本主菜单导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   main
# ------------------------------------------------------------------------------
main() {
    # 权限校验 (可选，如果不想让非root用户运行主菜单)
    # is_root || ui_warn "当前非 root 用户运行，部分功能可能受限。"

    while true; do
        ui clear
        ui print home_header "$(ui_spaces 1)▣$(ui_spaces 1)一款全功能的 Linux 管理脚本！ v$VSK_VERSION"
        ui print tip "$(ui_spaces 1)✦$(ui_spaces 1)命令行输入 ${BOLD_GREEN}v${LIGHT_YELLOW} 可快速启动脚本"
        # --- 菜单区域 ---
        ui line
        # 系统工具菜单项
        ui item 1 "系统工具 ▶"
        ui item 2 "基础工具 ▶"
        ui item 3 "进阶工具 ▶"
        ui item 4 "Docker 管理 ▶"
        ui line
        ui item 8 "测试脚本合集 ▶"
        ui item 9 "节点搭建脚本 ▶"
        ui line
        ui item 99 "脚本自管理 ▶"
        ui border_bottom
        ui item 0 "退出程序"
        ui border_bottom

        # --- 交互逻辑 ---
        choice=$(ui_read_choice)

        case "$choice" in
            1|2|3|4|8|9|99)
                if declare -f router_main > /dev/null; then
                    local ret=0
                    
                    # 调用路由分发，并捕获返回值
                    # 使用 || ret=$? 是为了防止 set -e (如果开启) 导致脚本直接退出
                    router_main "$choice" || ret=$?

                    # 检查返回值是否为 10 (重启信号)
                    if [[ $ret -eq 10 ]]; then
                        
                        ui_reload "ui_reload" "top"
                        sleep 1
                        
                        # 确保有执行权限
                        chmod +x "${BASE_DIR}/main.sh" 2>/dev/null
                        
                        # 执行原地重启
                        # 使用 exec 替换当前进程，"$0" 代表当前脚本路径，"$@" 代表启动参数
                        exec bash "$0" "$@"
                    fi
                else
                    ui_error "路由函数 router_main 未找到"
                    sleep 1
                fi
                ;;
            0)
                ui_exit
                ;;
            *)
                ui_error "无效选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 启动主函数
main "$@"

# # ******************************************************************************
# # 3. 命令行参数预处理
# # ******************************************************************************
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
