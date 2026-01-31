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

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************

# 导入环境变量
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib/env.sh"

# ==============================================================================
# 引入断点续传模块
source "${BASE_DIR}/lib/resume.sh"

# 加载业务逻辑库
source "${BASE_DIR}/modules/system/tuning/system_tune.sh"

# 接盘检查 (Check Resume Entry) 如果是重启自动回来的，这里会直接跳走去执行任务，不会往下走
check_resume_entry "$@"
# ==============================================================================

# 检测系统是否支持本脚本
# check_supported_os

# shellcheck disable=SC1091
source "${BASE_DIR}/modules/system/maintain/menu.sh"

# 开启严格模式
set -o errexit   # 一旦有命令返回非 0，立即退出脚本，避免错误被忽略
set -o pipefail  # 管道中任意一段失败，整体失败，防止错误被吞掉
set -o nounset   # 使用未定义变量时直接报错，避免拼写错误导致隐蔽 bug

# 将 ERR 信号捕获导向到我们定义的函数，并传入行号
trap 'error_handler $LINENO' ERR

# ------------------------------------------------------------------------------
# 函数名: _cleanup
# 功能:  捕捉错误的退出
# 
# 参数:
#   无
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
# 参数:
#   无
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
        print_error -m "当前解释器非 Bash，无法运行此脚本。"
        ptint_info -m "请尝试使用命令: bash main.sh 或 ./main.sh"
        exit 1
    fi

    # 2. 检查 Bash 版本是否满足最低要求
    if ((BASH_VERSINFO[0] < min_ver)); then
        print_error -m "需要 Bash 4.0+ (当前版本: $BASH_VERSION) " >&2
        print_tip "升级说明"
        print_echo "     - Debian/Ubuntu: apt install bash"
        print_echo "     - Alpine: apk add bash"
        exit 1
    fi
}

assert_bash_version

bash_help(){
    source "${BASE_DIR}/modules/system/maintain/help.sh"
    # ==============================================================================
    # 命令行参数解析 (CLI Argument Parser)
    # ==============================================================================
    # 如果传入了参数 ($# > 0)，则进入命令行模式；否则进入交互菜单模式
    if [[ $# -gt 0 ]]; then
        case "$1" in
            # --- 帮助与版本 ---
            -h|--help)
                v_help "${2:-}"
                exit 0
                ;;
            -v|--version)
                echo "v${VSK_VERSION:-0.1.0}"
                exit 0
                ;;
            -u|--update)
                update_script # 假设你有更新函数
                exit 0
                ;;
            
            # --- 软件管理映射 ---
            i|install|add)
                shift 1 # 移除第一个参数 (install)，保留后面的包名
                if [[ -z "$1" ]]; then
                    print_error "请指定要安装的软件包名"
                    exit 1
                fi
                pkg_install "$@" # 直接调用 package.sh 里的安装函数
                exit 0
                ;;
            rm|remove|uninstall)
                shift 1
                if [[ -z "$1" ]]; then
                    print_error "请指定要卸载的软件包名"
                    exit 1
                fi
                pkg_remove "$@"
                exit 0
                ;;
            
            # --- 系统功能映射 ---
            # swap)
            #     # 例如: v swap 2048
            #     if [[ -n "$2" ]]; then
            #         set_swap "$2"
            #     else
            #         print_error "请指定 Swap 大小 (MB)"
            #     fi
            #     exit 0
            #     ;;
            # ssl)
            #     # 如果后面还有参数，可以再细分，这里简单映射到菜单或函数
            #     ssl_menu 
            #     exit 0
            #     ;;
            
            # # --- Docker 映射 ---
            # docker)
            #     shift 1
            #     case "$1" in
            #         install)   docker_install_logic ;; # 需确保有此非交互函数
            #         uninstall) docker_remove_logic ;;
            #         *)         print_error "未知 Docker 指令. 试用: v docker install" ;;
            #     esac
            #     exit 0
            #     ;;

            # --- 未知参数 ---
            *)
                print_error "未知命令: $1"
                print_info "输入 'v -h' 查看帮助信息"
                exit 1
                ;;
        esac
    fi
}

bash_help "$@"

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
    # is_root || print_warn -m "当前非 root 用户运行，部分功能可能受限。"

    while true; do
        print_clear
        print_box_header "▣$(print_spaces 1)Linux 脚本工具箱！ v$VSK_VERSION"
        print_box_header_tip -h "$(print_spaces 1)✦$(print_spaces 1)命令行输入${GREEN} v ${YELLOW}可快速启动脚本"
        print_line
        print_menu_item -i 1 -s 2 -m "系统工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 2 -s 2 -m "基础工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 3 -s 2 -m "进阶工具" -I "$ICON_NAV" -T 2
        print_menu_item -i 4 -s 2 -m "Docker 管理" -I "$ICON_NAV" -T 2
        print_line
        print_menu_item -i 8 -s 2 -m "测试脚本合集" -I "$ICON_NAV" -T 2
        print_menu_item -i 9 -s 2 -m "节点搭建脚本" -I "$ICON_NAV" -T 2
        print_line
        print_menu_item -i 99 -s 1 -m "工具箱设置" -I "$ICON_NAV" -T 2
        print_line -c "="  
        print_menu_item -i 0 -s 2 -m "退出程序"
        print_line -c "="  

        choice=$(read_choice)

        case "$choice" in
            1|2|3|4|8|9|99)
                if declare -f router_main > /dev/null; then
                    local ret=0
                    
                    # 调用路由分发，并捕获返回值
                    # 使用 || ret=$? 是为了防止 set -e (如果开启) 导致脚本直接退出
                    router_main "$choice" || ret=$?

                    # 检查返回值是否为 10 (重启信号)
                    if [[ $ret -eq 10 ]]; then
                        
                        print_step -m "脚本正在重启..."
                        sleep 1
                        
                        # 确保有执行权限
                        chmod +x "${BASE_DIR}/main.sh" 2>/dev/null
                        
                        # 执行原地重启
                        # 使用 exec 替换当前进程，"$0" 代表当前脚本路径，"$@" 代表启动参数
                        exec bash "$0" "$@"
                    fi
                else
                    print_error "路由函数 router_main 未找到"
                    sleep 1
                fi
                ;;
            0)
                print_exit
                ;;
            *)
                print_error -m "无效选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 启动主函数
main "$@"
