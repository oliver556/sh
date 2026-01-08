#!/usr/bin/env bash

# =================================================================================
# @名称:        uninstall.sh
# @功能描述:     VpsScriptKit 卸载脚本
# @作者:        Jamison
# @版本:        1.3.0
# @修改日期:     2026-01-07
# @许可证:       MIT
# =================================================================================

set -Eeuo pipefail

# ------------------------------
# 基础配置
# ------------------------------
INSTALL_DIR="/opt/VpsScriptKit"

BIN_PATHS=(
    "/usr/local/bin/v"
    "/usr/local/bin/vsk"
    "/usr/bin/v"
    "/usr/bin/vsk"
)

# ------------------------------
# 颜色定义
# ------------------------------
BOLD_RED=$(tput bold 2>/dev/null; tput setaf 1 2>/dev/null) || BOLD_RED=""
BOLD_GREEN=$(tput bold 2>/dev/null; tput setaf 2 2>/dev/null) || BOLD_GREEN=""
BOLD_CYAN=$(tput bold 2>/dev/null; tput setaf 6 2>/dev/null) || BOLD_CYAN=""
BOLD_WHITE=$(tput bold 2>/dev/null; tput setaf 7 2>/dev/null) || BOLD_WHITE=""
RESET=$(tput sgr0 2>/dev/null) || RESET=""

trap 'echo -e "\n${BOLD_RED}❌ 卸载过程中出现异常${RESET}" >&2' ERR

# ------------------------------
# 功能：执行卸载
# ------------------------------
do_uninstall() {

    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${BOLD_RED}错误：请使用 root 权限执行卸载${RESET}"
        return 1
    fi

    clear
    echo -e "${BOLD_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD_RED}        ⚠️$(ui_spaces 4)正在卸载 VpsScriptKit${RESET}"
    echo -e "${BOLD_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "${BOLD_WHITE}该操作将完全移除脚本及所有命令。${RESET}"
    echo

    printf "${BOLD_CYAN}确认继续卸载？(y/N): ${RESET}"
    read -r confirm < /dev/tty || confirm="n"
    confirm="${confirm,,}"

    if [[ "$confirm" != "y" ]]; then
        echo
        echo -e "${BOLD_GREEN}已取消卸载。${RESET}"
        echo
        return 0
    fi

    echo

    echo -e "${BOLD_CYAN}🧹 正在清理系统...${RESET}"

    for path in "${BIN_PATHS[@]}"; do
        [[ -e "$path" || -L "$path" ]] && rm -f "$path"
    done

    [[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"

    # hash -r 2>/dev/null || true

    echo
    echo -e "${BOLD_GREEN}✅$(ui_spaces)VpsScriptKit 已彻底卸载完成${RESET}"
    echo
    echo -e "${BOLD_CYAN}📦$(ui_spaces)所有组件已清理，感谢使用。${RESET}"
    echo

    sleep 2

    clear
}

# ------------------------------
# 脚本入口
# ------------------------------
do_uninstall "$@"

exit 0
