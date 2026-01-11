#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 重装脚本
# 
# @文件路径: modules/system/maintain/reinstall.sh
# @功能描述: 强制重装最新版本脚本
# 
# @作者:    Jamison
# @版本:    0.1.0
# @创建日期: 2026-01-09
# ==============================================================================

# ******************************************************************************
# Shell 环境安全设置（工程级）
# ******************************************************************************
set -Eeuo pipefail
trap 'echo -e "${BOLD_RED}错误: 更新在第 $LINENO 行失败${RESET}" >&2' ERR



# ******************************************************************************
# 环境初始化 (智能加载)
# ******************************************************************************
# 确保 BASE_DIR 存在 (兼容独立运行模式)
if [[ -z "${BASE_DIR:-}" ]]; then
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do
        DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    export BASE_DIR="$( cd -P "$( dirname "$SOURCE" )"/../../.. >/dev/null 2>&1 && pwd )"
fi

# 智能加载库文件
if ! declare -f ui > /dev/null; then
    source "${BASE_DIR}/lib/env.sh"
    source "${BASE_DIR}/lib/utils.sh"
    source "${BASE_DIR}/lib/ui.sh"
    source "${BASE_DIR}/lib/interact.sh"
fi

# ------------------------------------------------------------------------------
# 函数名: do_reinstall
# 功能:  强制重新安装脚本
# 
# 参数: 无
# 
# 返回值:
#   10 - 更新成功，通知主程序重启
# 
# 示例:
#   do_reinstall
# ------------------------------------------------------------------------------

do_reinstall() {
    ui clear
    ui print info_header "正在强制重新安装并修复环境..."
    ui blank

    # 1. 使用 bash -s -- 传递参数给远程下载的脚本
    # 2. 传递 --skip-agreement 让 install.sh 识别并跳过确认环节
    if curl -sL vsk.viplee.cc | bash -s -- --skip-agreement; then
        ui blank
        ui echo "${BOLD_GREEN}✅ 强制重新安装完成！${RESET}"
        sleep 2
        # 返回 10 告诉父进程 (main.sh) 需要重启
        exit 10
    else
        ui_error "强制安装过程中出现异常"
        ui_wait_enter
        exit 1
    fi
}

# 启动重装逻辑
do_reinstall "$@"