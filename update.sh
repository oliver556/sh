#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 核心更新引擎 (不含菜单，只负责逻辑执行)
# @名称:         update.sh
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-06
# @修改日期:     2025-01-06
#
# @许可证:       MIT
# ============================================================

# 严谨模式：遇到错误即退出
set -Eeuo pipefail
trap 'echo -e "${BOLD_RED}错误: 更新在第 $LINENO 行失败${RESET}" >&2' ERR

# ------------------------------
# 1. 环境初始化
# ------------------------------
# 获取脚本的物理路径并推导根目录 (处理软链接)
REAL_PATH=$(readlink -f "$0" 2>/dev/null || echo "$0")
export BASE_DIR="${BASE_DIR:-$(cd "$(dirname "$REAL_PATH")" && pwd)}"

INSTALL_DIR="$BASE_DIR"
REPO="oliver556/sh"
VERSION_FILE="$INSTALL_DIR/version"

# 颜色定义
BOLD_RED=$(tput bold)$(tput setaf 1)
BOLD_GREEN=$(tput bold)$(tput setaf 2)
BOLD_YELLOW=$(tput bold)$(tput setaf 3)
BOLD_BLUE=$(tput bold)$(tput setaf 4)
BOLD_CYAN=$(tput bold)$(tput setaf 6)
RESET=$(tput sgr0)

# ------------------------------
# 2. 版本检测逻辑
# ------------------------------
get_versions() {
    # 读取本地版本
    local_ver="0.0.0"
    [ -f "$VERSION_FILE" ] && local_ver=$(cat "$VERSION_FILE" | xargs)

    # 获取远程最新版本号 (GitHub API)
    echo -e "${BOLD_CYAN}🔎 正在检查远程版本...${RESET}"
    # 使用 curl 获取最新 Tag
    remote_ver=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | cut -d '"' -f 4 | xargs || echo "")

    if [ -z "$remote_ver" ]; then
        echo -e "${BOLD_RED}错误: 无法获取远程版本信息，请检查网络。${RESET}"
        exit 1
    fi
    
    # 导出变量供 do_update 使用
    export LOCAL_VER="$local_ver"
    export REMOTE_VER="$remote_ver"
}

# ------------------------------
# 3. 执行更新与原地重启
# ------------------------------
do_update() {
    get_versions

    # 版本比对逻辑 (兼容 v1.0.0 和 1.0.0 的格式)
    if [ "$LOCAL_VER" == "$REMOTE_VER" ] || [ "v$LOCAL_VER" == "$REMOTE_VER" ]; then
        echo -e "${BOLD_GREEN}✅ 当前已是最新版本 ($LOCAL_VER)。${RESET}"
        # 退出码 0：告知父脚本无需重启
        exit 0
    fi

    echo -e "${BOLD_YELLOW}🚀 发现新版本 $REMOTE_VER (当前: v$LOCAL_VER)${RESET}"
    echo -e "${BOLD_BLUE}正在执行更新...${RESET}"
    sleep 1
    
    # 核心逻辑：直接调用远程的一键安装脚本，并传递跳过协议参数
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        echo -e "\n${BOLD_GREEN}✅ 更新完成！${RESET}"
        echo -e "${BOLD_CYAN}🔄 正在原地重启脚本...${RESET}"
        # 返回退出码 10，告诉 vsk_script/menu.sh：更新已成功，请主程序执行 exec v 重启
        exit 10
    else
        echo -e "${BOLD_RED}❌ 更新失败。${RESET}"
        exit 1
    fi
}

# 启动引擎
do_update