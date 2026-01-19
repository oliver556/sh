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
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

# 检测系统是否支持本脚本
# check_supported_os

# shellcheck disable=SC1091
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
  print_exit
}
trap _cleanup SIGINT SIGTERM

# ------------------------------------------------------------------------------
# 函数名: assert_bash_version
# 功能:  Bash 版本检查
# 
# 参数: 无
# 
# 返回值:
#   0 - 错误时的信息提示
# 
# 示例:
#   assert_bash_version
# ------------------------------------------------------------------------------
assert_bash_version() {
    local min_ver=4

    # 1. 防止被 sh / dash (Ubuntu默认sh) 运行
    if [ -z "$BASH_VERSION" ]; then
        ui_error "当前解释器非 Bash，无法运行此脚本。"
        ui_tip "请尝试使用命令：bash main.sh 或 ./main.sh"
        exit 1
    fi

    # 2. 检查 Bash 版本是否满足最低要求
    if ((BASH_VERSINFO[0] < min_ver)); then
        ui_error "需要 Bash 4.0+ (当前版本: $BASH_VERSION) " >&2
        ui_tip "升级说明"
        ui_text "     - Debian/Ubuntu: apt install bash"
        ui_text "     - Alpine: apk add bash"
        exit 1
    fi
}

assert_bash_version
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
        print_clear
        print_box_header "$(ui_spaces 1)▣$(ui_spaces 1)一款全功能的 Linux 管理脚本！ v$VSK_VERSION"
        print_box_header_tip "$(ui_spaces 1)✦$(ui_spaces 1)命令行输入${GREEN} v ${YELLOW}可快速启动脚本"
        print_line
        print_menu_item -i 1 -s 2 -m "系统工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 2 -s 2 -m "基础工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 3 -s 2 -m "进阶工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 4 -s 2 -m "Docker 管理" -I "$ICON_NAV" -T 2
        print_line
        print_menu_item -i 8 -s 2 -m "测试脚本合集" -I "$ICON_NAV" -T 2
        print_menu_item -i 9 -s 2 -m "节点搭建脚本" -I "$ICON_NAV" -T 2
        print_line
        print_menu_item -i 99 -s 1 -m "脚本自管理" -I "$ICON_NAV" -T 2
        print_line -c "="  
        print_menu_item -i 0 -s 2 -m "退出程序"
        print_line -c "="  

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
