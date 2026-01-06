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

    echo -e "\n${BOLD_CYAN}正在清理系统环境...${RESET}"

    # 1. 移除软链接
    echo -e "--> 移除快捷命令..."
    rm -f "$BIN_LINK" "$BIN_SHORT_LINK" 2>/dev/null || true

    # 2. 移除主目录
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "--> 移除安装目录: $INSTALL_DIR"
        # 即使目录内有文件正在被占用，也尝试强制递归删除
        rm -rf "$INSTALL_DIR" || {
            echo -e "${BOLD_YELLOW}普通删除失败，尝试提升权限强制清理...${RESET}"
            rm -rf "$INSTALL_DIR" 2>/dev/null || true
        }
    fi

    # 再次验证目录是否消失（防止设备忙等特殊情况）
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BOLD_RED}提示: 目录 $INSTALL_DIR 仍有部分残留，建议手动运行 rm -rf $INSTALL_DIR${RESET}"
    fi

    echo -e "${LIGHT_CYAN}✅ 卸载成功，江湖有缘再见！${LIGHT_WHITE}"
    echo -e "${BOLD_YELLOW}注意: 如果输入 'v' 仍报错，请运行 'hash -r' 刷新 Shell 缓存。${RESET}"
    echo
    
    # 成功卸载返回 0，让 maintain.sh 捕捉到并退出整个脚本
    exit 0
}

# 执行卸载
do_uninstall
