#!/usr/bin/env bash

### ============================================================
# VpsScriptKit - 颜色 - 定义库
# @名称:         color.sh
# @职责:
# - 提供终端颜色变量
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-01
# @修改日期:     2025-01-04
#
# @许可证:       MIT
### ============================================================

# ------------------------------
# 文本颜色
# ------------------------------
BLACK=$(tput setaf 0)    # 黑色
RED=$(tput setaf 1)      # 红色
GREEN=$(tput setaf 2)    # 绿色
YELLOW=$(tput setaf 3)   # 黄色
BLUE=$(tput setaf 4)     # 蓝色
MAGENTA=$(tput setaf 5)  # 品红色
CYAN=$(tput setaf 6)     # 青色
WHITE=$(tput setaf 7)    # 白色
GREY=$(tput setaf 8)     # 灰色
RESET=$(tput sgr0)       # 重置
BOLD=$(tput bold)        # 加粗
LIGHT_CYAN=$(tput setaf 14)     # 亮青色
LIGHT_GREEN=$(tput setaf 10)    # 亮绿色
LIGHT_YELLOW=$(tput setaf 11)   # 亮黄色
LIGHT_BLUE=$(tput setaf 12)     # 亮蓝色
LIGHT_MAGENTA=$(tput setaf 13)  # 亮品红色
LIGHT_RED=$(tput setaf 9)       # 亮红色
LIGHT_WHITE=$(tput setaf 15)    # 亮白色
LIGHT_GREY=$(tput setaf 245)    # 亮灰色
BOLD_BLACK=$(tput bold)$(tput setaf 0)    # 加粗黑色
BOLD_RED=$(tput bold)$(tput setaf 1)      # 加粗红色
BOLD_GREEN=$(tput bold)$(tput setaf 2)    # 加粗绿色
BOLD_YELLOW=$(tput bold)$(tput setaf 3)   # 加粗黄色
BOLD_BLUE=$(tput bold)$(tput setaf 4)     # 加粗蓝色
BOLD_MAGENTA=$(tput bold)$(tput setaf 5)  # 加粗品红色
BOLD_CYAN=$(tput bold)$(tput setaf 6)     # 加粗青色
BOLD_WHITE=$(tput bold)$(tput setaf 7)    # 加粗白色
BOLD_GREY=$(tput bold)$(tput setaf 8)     # 加粗灰色
BOLD_LIGHT_CYAN=$(tput bold)$(tput setaf 14)     # 加粗亮青色
BOLD_LIGHT_GREEN=$(tput bold)$(tput setaf 10)    # 加粗亮绿色
BOLD_LIGHT_YELLOW=$(tput bold)$(tput setaf 11)   # 加粗亮黄色
BOLD_LIGHT_BLUE=$(tput bold)$(tput setaf 12)     # 加粗亮蓝色
BOLD_LIGHT_MAGENTA=$(tput bold)$(tput setaf 13)  # 加粗亮品红色
BOLD_LIGHT_RED=$(tput bold)$(tput setaf 9)       # 加粗亮红色
BOLD_LIGHT_WHITE=$(tput bold)$(tput setaf 15)    # 加粗亮白色

# ------------------------------
# 背景颜色
# ------------------------------
### === 暗色背景 === ###
ON_BLACK=$(tput setab 0)    # 黑色背景
ON_RED=$(tput setab 1)      # 红色背景
ON_GREEN=$(tput setab 2)    # 绿色背景
ON_YELLOW=$(tput setab 3)   # 黄色背景
ON_BLUE=$(tput setab 4)     # 蓝色背景
ON_MAGENTA=$(tput setab 5)  # 品红色背景
ON_CYAN=$(tput setab 6)     # 青色背景
ON_WHITE=$(tput setab 7)    # 白色背景

### === 亮色背景 === ###
ON_LIGHT_GREY=$(tput setab 250)    # 亮灰色背景
ON_LIGHT_GREEN=$(tput setab 118)   # 亮绿色背景
ON_LIGHT_YELLOW=$(tput setab 226)  # 亮黄色背景
ON_LIGHT_BLUE=$(tput setab 39)     # 亮蓝色背景
ON_LIGHT_MAGENTA=$(tput setab 165) # 亮品红色背景
ON_LIGHT_CYAN=$(tput setab 51)     # 亮青色背景
ON_LIGHT_WHITE=$(tput setab 255)   # 亮白色背景

# ------------------------------
# 特定的文本属性
# ------------------------------
SHANSHUO=$(tput blink)       # 闪烁（不是所有终端都支持）
WUGUANGBIAO=$(tput civis)    # 隐藏光标
GUANGBIAO=$(tput cnorm)      # 恢复光标
UNDERLINE=$(tput smul)       # 下划线
RESET_UNDERLINE=$(tput rmul) # 重置下划线
# DIM=$(tput dim)              # 变暗
STANDOUT=$(tput smso)        # 突出显示（翻转前景色和背景色）
RESET_STANDOUT=$(tput rmso)  # 重置突出显示
TITLE=${STANDOUT}            # 使用突出显示来作为标题
JIAOCU=${RESET}${BOLD}       # 加粗

# ------------------------------
# 字体加背景色
# ------------------------------
BAI_HUANGSE=${WHITE}${ON_YELLOW}   # 白黄色
BAI_LANSE=${WHITE}${ON_BLUE}       # 白蓝色
BAI_LVSE=${WHITE}${ON_GREEN}       # 白绿色
BAI_QINGSE=${WHITE}${ON_CYAN}      # 白青色
BAI_HONGSE=${WHITE}${ON_RED}       # 白红色
BAI_ZISE=${WHITE}${ON_MAGENTA}     # 白紫色
HEI_BAISE=${BLACK}${ON_WHITE}      # 黑白色
HEI_HUANGSE=${ON_YELLOW}${BLACK}   # 黑黄色

# ------------------------------
# 提示字样
# ------------------------------
CW="${BOLD}${BAI_HUANGSE} ERROR ${JIAOCU}"     # 表示 "ERROR" 的提示
ZY="${BAI_HONGSE}${BOLD} ATTENTION ${JIAOCU}"  # 表示 "ATTENTION" 的提示
JG="${BAI_HONGSE}${BOLD} WARNING ${JIAOCU}"    # 表示 "WARNING" 的提示

