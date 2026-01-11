#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 核心更新引擎 (不含菜单，只负责逻辑执行)
# 
# @文件路径: modules/system/maintain/update.sh
# @功能描述: 环境初始化、依赖加载、主菜单渲染与路由分发
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-06
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************

# 严谨模式：遇到错误即退出
set -Eeuo pipefail
trap 'echo -e "${BOLD_RED}错误: 更新在第 $LINENO 行失败${RESET}" >&2' ERR

# ******************************************************************************
# 环境初始化
# ******************************************************************************
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

# 智能加载库文件：如果 ui 函数未定义（bash 调用模式），则加载库；
# 如果已定义（source 调用模式），则跳过加载，避免覆盖。
if ! declare -f ui > /dev/null; then
    source "${BASE_DIR}/lib/env.sh"
    source "${BASE_DIR}/lib/utils.sh"
    source "${BASE_DIR}/lib/ui.sh"
    source "${BASE_DIR}/lib/interact.sh"
fi

# ------------------------------------------------------------------------------
# 函数名: get_versions
# 功能:   获取版本
# 参数: 无
#
# 返回值:
#   LOCAL_VER - 本地版本
#   REMOTE_VER - 远端版本
# 
# 示例:
#   get_versions
# ------------------------------------------------------------------------------
get_versions() {
    # 获取本地版本
    if [[ -f "${BASE_DIR}/version" ]]; then
        LOCAL_VER=$(cat "${BASE_DIR}/version" | xargs)
    else
        LOCAL_VER="Unknown"
    fi

    ui echo "${BOLD_CYAN}🔎 正在检查远程版本...${RESET}"
    
    # 获取远程最新版本 (GitHub API)
    # 使用 curl 获取，设置超时时间防止卡死
    REMOTE_VER=$(curl -fsSL --connect-timeout 5 "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | cut -d '"' -f 4 | xargs || echo "")

    if [[ -z "$REMOTE_VER" ]]; then
        ui_error "无法获取远程版本信息，请检查网络连接。"
        return 1
    fi
    
    # 导出变量供 do_update 使用
    export LOCAL_VER="$LOCAL_VER"
    export REMOTE_VER="$REMOTE_VER"
}

# ------------------------------------------------------------------------------
# 函数名: do_update
# 功能:   执行更新与原地重启
# 参数: 无
#
# 返回值:
#   10 - 更新成功，通知主程序重启
# 
# 示例:
#   do_update
# ------------------------------------------------------------------------------
do_update() {
    ui clear
    ui print info_header "正在检查更新逻辑..."
    ui blank

    # 获取并比对版本
    if ! get_versions; then
        ui_wait_enter
        exit 1
    fi

    # 版本比对
    if [[ "$LOCAL_VER" == "$REMOTE_VER" ]] || [[ "v$LOCAL_VER" == "$REMOTE_VER" ]]; then
        ui echo "${BOLD_GREEN}✅ 当前已是最新版本 ($LOCAL_VER)。${RESET}"
        ui_wait_enter
        exit 0
    fi

    # # 发现新版本，询问是否更新
    # ui echo "${BOLD_YELLOW}🚀 发现新版本！${RESET}"
    # if ! ui_confirm "是否立即执行更新？"; then
    #     ui_info "更新已取消。"
    #     exit 0
    # fi

    # 执行更新 (下载 install.sh 并运行)
    ui blank
    ui_info "正在拉取最新代码..."
    
    # 直接调用远程的一键安装脚本，并传递跳过协议参数
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        ui blank
        ui echo "${BOLD_GREEN}✅ 更新完成！${RESET}"
        sleep 1
        exit 10
    else
        ui_error "更新失败，请检查网络或稍后重试。"
        ui_wait_enter
        exit 1
    fi
}

# 启动引擎
do_update "$@"