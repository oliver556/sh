#!/usr/bin/env bash

# =================================================================================
# @名称:         update.sh
# @功能描述:     VpsScriptKit 自更新脚本
# =================================================================================

# --- 基础配置 ---
INSTALL_DIR="/opt/VpsScriptKit"
REPO="oliver556/sh"
VERSION_FILE="$INSTALL_DIR/version"

# --- 颜色 ---
BOLD_GREEN=$(tput bold)$(tput setaf 2)
BOLD_BLUE=$(tput bold)$(tput setaf 4)
BOLD_YELLOW=$(tput bold)$(tput setaf 3)
RESET=$(tput sgr0)

# --- 更新逻辑 ---
check_update() {
    echo -e "${BOLD_BLUE}🔎 正在检查远程版本...${RESET}"
    
    # 1. 获取本地版本
    local local_ver="Unknown"
    [ -f "$VERSION_FILE" ] && local_ver=$(cat "$VERSION_FILE")

    # 2. 获取远程最新版本号 (从 GitHub Release Tag)
    local remote_ver
    remote_ver=$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | cut -d '"' -f 4)

    if [ -z "$remote_ver" ]; then
        echo "无法获取远程版本，请检查网络。"
        return 1
    fi

    if [ "$local_ver" == "$remote_ver" ]; then
        echo -e "${BOLD_GREEN}✅ 当前已是最新版本 ($local_ver)。${RESET}"
        return 0
    fi

    echo -e "${BOLD_YELLOW}🚀 发现新版本 $remote_ver (当前: $local_ver)，准备更新...${RESET}"
    
    # 3. 调用安装脚本重新覆盖即可实现更新
    # 这样做可以复用安装逻辑，确保环境一致性
    curl -sL vsk.viplee.cc | bash
}

check_update