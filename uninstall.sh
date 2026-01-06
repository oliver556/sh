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
trap 'echo -e "\n${BOLD_RED}错误: 卸载过程中出现异常${RESET}" >&2' ERR

# ------------------------------
# 1. 基础配置
# ------------------------------
INSTALL_DIR="/opt/VpsScriptKit"
BIN_LINK="/usr/local/bin/vsk"
BIN_SHORT_LINK="/usr/local/bin/v"

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
        echo -e "\n${BOLD_GREEN}已取消操作，未进行任何更改。${RESET}"
        sleep 1
        exit 1 # 返回 1 告诉 maintain.sh 卸载取消，不要退出程序
    fi

    echo -e "\n${LIGHT_CYAN}🧹 正在清理卸载...${LIGHT_WHITE}"

    # --- 开始物理清理 ---
    # 1. 强制删除所有可能的二进制/链接
    for path in "${BIN_PATHS[@]}"; do
        rm -f "$path" 2>/dev/null || true
    done

    # 2. 删除主目录
    rm -rf "$INSTALL_DIR" 2>/dev/null || true

    # 3. 强制刷新当前 Shell 缓存
    hash -r 2>/dev/null || true

    # 4. 视觉终点
    clear
    echo -e "${BOLD_GREEN}✅ 卸载成功，江湖有缘再见！${RESET}"
    
    # --- 终极手段：自杀并杀掉父进程 ---
    # 找到所有包含 VpsScriptKit 字符的 bash 进程并全部杀掉
    # 这样能确保 maintain.sh 的循环被物理切断，绝对无法回到菜单
    # 使用 2>/dev/null 隐藏 Killed 提示，追求极致纯净
    (sleep 1 && pkill -9 -f "VpsScriptKit") & 
    exit 0
}

# 执行卸载
do_uninstall
