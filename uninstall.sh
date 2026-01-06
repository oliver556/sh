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
    
    # 直接进行是与否的确认，不再列出多余的菜单
    local choice
    printf "${BOLD_CYAN}您确定要执行完全卸载吗？(y/N): ${RESET}"
    # 使用 /dev/tty 确保能捕获输入
    read -r choice < /dev/tty || choice="n"
    
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    if [[ "$choice" != "y" ]]; then
        echo -e "\n${BOLD_GREEN}已取消操作，未进行任何更改。${RESET}"
        sleep 1
        return 0
    fi

    echo -e "\n${BOLD_CYAN}正在清理系统环境...${RESET}"

    # 1. 移除软链接
    [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ] && rm -f "$BIN_LINK" && echo -e "  - 移除 $BIN_LINK"
    [ -L "$BIN_SHORT_LINK" ] || [ -f "$BIN_SHORT_LINK" ] && rm -f "$BIN_SHORT_LINK" && echo -e "  - 移除 $BIN_SHORT_LINK"

    # 2. 移除主目录
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo -e "  - 移除 $INSTALL_DIR"
    fi

    echo -e "\n${BOLD_GREEN}✅ 卸载成功！VpsScriptKit 已彻底移除。${RESET}"
    echo -e "${BOLD_YELLOW}期待下次与您相遇！${RESET}"
    echo
    
    # 卸载后强制退出，防止回到已不存在的菜单
    exit 0
}

# 执行卸载
do_uninstall