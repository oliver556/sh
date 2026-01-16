#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 颜色 - 定义库
#
# @文件路径: lib/color.sh
# @功能描述: 提供终端颜色变量
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-01
# ==============================================================================

# ******************************************************************************
# 颜色定义
# ******************************************************************************
# shellcheck disable=SC2155
{
    declare -rx RED=$(tput setaf 1)       # 红色 (错误/危险)
    declare -rx GREEN=$(tput setaf 2)     # 绿色 (成功/通过)
    declare -rx YELLOW=$(tput setaf 3)    # 黄色 (警告/注意)
    declare -rx BLUE=$(tput setaf 4)      # 蓝色 (信息/普通)
    declare -rx PURPLE=$(tput setaf 5)    # 紫色 (强调/特殊)
    declare -rx CYAN=$(tput setaf 6)      # 青色 (调试/路径)
    declare -rx WHITE=$(tput setaf 7)     # 白色 (正文)
    declare -rx GREY=$(tput setaf 8)      # 灰色 (正文)

    declare -rx BOLD=$(tput bold)         # 加粗 (用于标题/重点)
    declare -rx DIM=$(tput dim)           # 暗淡 (用于次要信息/注释)
    declare -rx NC=$(tput sgr0)           # 重置 (No Color，清除所有格式)

    declare -rx BOLD_RED="${BOLD}${RED}"       # 加粗红色 (错误/危险)
    declare -rx BOLD_GREEN="${BOLD}${GREEN}"   # 加粗绿色 (成功/通过)
    declare -rx BOLD_YELLOW="${BOLD}${YELLOW}" # 加粗黄色 (警告/注意)
    declare -rx BOLD_BLUE="${BOLD}${BLUE}"     # 加粗蓝色 (信息/普通)
    declare -rx BOLD_CYAN="${BOLD}${CYAN}"     # 加粗青色 (调试/路径)
    declare -rx BOLD_WHITE="${BOLD}${WHITE}"   # 加粗白色 (正文)
    declare -rx BOLD_GREY="${BOLD}${GREY}"     # 加粗灰色 (正文)
}
