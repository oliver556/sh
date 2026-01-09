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
    # 读取本地版本
    local_ver="0.0.0"
    [ -f "$VSK_VERSION" ] && local_ver=$(cat "$VSK_VERSION" | xargs)

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

# ------------------------------------------------------------------------------
# 函数名: do_update
# 功能:   执行更新与原地重启
# 参数: 无
#
# 返回值:
#   执行对应的函数功能
# 
# 示例:
#   do_update
# ------------------------------------------------------------------------------
do_update() {
    get_versions

    # 版本比对逻辑 (兼容 v1.0.0 和 1.0.0 的格式)
    if [ "$LOCAL_VER" == "$REMOTE_VER" ] || [ "v$LOCAL_VER" == "$REMOTE_VER" ]; then
        ui_success "当前已是最新版本 ($LOCAL_VER)。${RESET}"
        # 退出码 0：告知父脚本无需重启
        exit 0
    fi

    ui_info "发现新版本 $REMOTE_VER (当前: v$LOCAL_VER)"
    ui_info "${BOLD_BLUE}正在执行更新...${RESET}"
    sleep 1
    
    # 直接调用远程的一键安装脚本，并传递跳过协议参数
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        echo -e "\n${BOLD_GREEN}✅ 更新完成！${RESET}"
        echo -e "${BOLD_CYAN}🔄 正在原地重启脚本...${RESET}"
        # 返回退出码 10，告诉 父 shell 进程 menu.sh: 更新已成功，请主程序执行 exec v 重启
        exit 10
    else
        ui_error "更新失败。${RESET}"
        exit 1
    fi
}

# 启动引擎
do_update