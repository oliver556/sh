#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 核心更新引擎 (不含菜单，只负责逻辑执行)
# 
# @文件路径: modules/system/maintain/update.sh
# @功能描述: 环境初始化、依赖加载、主菜单渲染与路由分发
# 
# @作者:    Jamison
# @版本:    0.1.0
# @创建日期: 2026-01-06
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************

# 严谨模式：遇到错误即退出
set -Eeuo pipefail
trap 'echo -e "${BOLD_RED}错误: 更新在第 $LINENO 行失败${NC}" >&2' ERR

# ******************************************************************************
# 环境初始化
# ******************************************************************************
source "${BASE_DIR}/lib/env.sh"

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

    ui_search "正在检查远程版本..."
    
    # 获取远程最新版本 (GitHub API)，使用 curl 获取，设置超时时间防止卡死
    REMOTE_VER=$(curl -fsSL --connect-timeout 5 "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | cut -d '"' -f 4 | xargs || echo "")

    if [[ -z "$REMOTE_VER" ]]; then
        ui_error "无法获取远程版本信息，请检查网络连接。"
        return 1
    fi
    
    export LOCAL_VER
    export REMOTE_VER
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
    ui_box_info "检查版本" "bottom"

    # 获取并比对版本
    if ! get_versions; then
        ui_wait_enter
        exit 1
    fi

    # 版本比对
    if [[ "$LOCAL_VER" == "$REMOTE_VER" ]] || [[ "v$LOCAL_VER" == "$REMOTE_VER" ]]; then
        ui_box_success "当前已是最新版本" "($LOCAL_VER)" "top"
        ui_wait_enter
        exit 0
    else
        ui_tip "发现新版本"
    fi

    ui blank
    ui_info "正在拉取最新代码..."
    sleep 1
    
    # 直接调用远程的一键安装脚本，并传递跳过协议参数
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        ui_box_success "更新完成！" "top"
        sleep 1
        exit 10
    else
        ui_box_error "更新失败，请检查网络或稍后重试。" "top"
        ui_wait_enter
        exit 1
    fi
}

# 启动引擎
do_update "$@"