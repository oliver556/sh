#!/usr/bin/env bash

# =================================================================================
# @名称:        uninstall.sh
# @功能描述:     VpsScriptKit 卸载脚本 (精简直接确认版)
# @作者:        Jamison
# @版本:        1.1.0
# @修改日期:     2026-01-06
#
# @许可证:       MIT
# =================================================================================

# 严谨模式
set -Eeuo pipefail
trap 'echo -e "\n${BOLD_RED}错误: 卸载过程中出现异常，请检查权限${RESET}" >&2' ERR

# ------------------------------
# 1. 基础配置
# ------------------------------
INSTALL_DIR="/opt/VpsScriptKit"
# 定义所有可能存在的快捷命令路径，彻底解决残留问题
BIN_PATHS=(
    "/usr/local/bin/v"
    "/usr/local/bin/vsk"
    "/usr/bin/v"
    "/usr/bin/vsk"
)

# 颜色定义
BOLD_RED=$(tput bold)$(tput setaf 1) || BOLD_RED=""
BOLD_GREEN=$(tput bold)$(tput setaf 2) || BOLD_GREEN=""
BOLD_YELLOW=$(tput bold)$(tput setaf 3) || BOLD_YELLOW=""
BOLD_CYAN=$(tput bold)$(tput setaf 6) || BOLD_CYAN=""
BOLD_WHITE=$(tput bold)$(tput setaf 7) || BOLD_WHITE=""
RESET=$(tput sgr0) || RESET=""

# ------------------------------
# 2. 卸载逻辑
# ------------------------------
do_uninstall() {
    # 权限检查
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${BOLD_RED}错误: 请使用 root 权限运行此脚本。${RESET}"
        exit 1
    fi

    clear
    echo -e "${BOLD_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD_RED}        ⚠️  警告：正在执行 VpsScriptKit 卸载程序${RESET}"
    echo -e "${BOLD_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD_WHITE}这将彻底从系统中移除脚本主目录及所有快捷命令 (${BOLD_YELLOW}v${BOLD_WHITE}/${BOLD_YELLOW}vsk${BOLD_WHITE})。${RESET}"
    echo
    
    local choice
    printf "${BOLD_CYAN}您确定要执行完全卸载吗？(y/N): ${RESET}"
    # 强制从终端使用 /dev/tty读取输入，确保管道调用时也能交互
    read -r choice < /dev/tty || choice="n"
    
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$choice" != "y" ]]; then
        echo -e "\n${BOLD_GREEN}已取消卸载，未进行任何更改。${RESET}"
        sleep 1
        exit 1 # 返回 1 告知父进程：操作已取消
    fi

    echo -e "\n${LIGHT_CYAN}🧹 正在清理卸载...${LIGHT_WHITE}"

     # 1. 遍历清理所有快捷链接 (物理抹除)
    for path in "${BIN_PATHS[@]}"; do
        if [ -L "$path" ] || [ -f "$path" ]; then
            echo -e "--> 移除命令: $path"
            rm -f "$path" 2>/dev/null || true
        fi
    done

    # 2. 移除安装主目录
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "--> 移除安装目录: $INSTALL_DIR"
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
    fi

    # 3. 刷新子进程的命令哈希
    hash -r 2>/dev/null || true

    # 4. 返回约定好的信号码 15
    # 这个状态码告诉 maintain.sh：卸载已完成，请执行自毁并告别
    exit 15
}

# 执行卸载
do_uninstall
