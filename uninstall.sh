#!/usr/bin/env bash

# =================================================================================
# @名称:         uninstall.sh
# @功能描述:     VpsScriptKit 卸载脚本
# =================================================================================

INSTALL_DIR="/opt/VpsScriptKit"
BIN_LINK="/usr/local/bin/vsk"
BIN_SHORT_LINK="/usr/local/bin/v"

# 颜色
BOLD_RED=$(tput bold)$(tput setaf 1)
BOLD_CYAN=$(tput bold)$(tput setaf 6)
RESET=$(tput sgr0)

confirm_uninstall() {
    echo -e "${BOLD_RED}⚠️  警告: 这将完全删除 VpsScriptKit 及其所有配置文件。${RESET}"
    read -rp "确定要卸载吗？(y/n): " choice
    case "$choice" in
        y|Y )
            echo -e "${BOLD_CYAN}🧹 正在清理系统残留...${RESET}"
            rm -rf "$INSTALL_DIR"
            rm -f "$BIN_LINK"
            rm -f "$BIN_SHORT_LINK"
            sleep 1
            echo -e "${BOLD_RED}✅ 卸载完成，期待下次相遇！${RESET}"
            ;;
        * )
            echo "已取消卸载。"
            ;;
    esac
}

confirm_uninstall