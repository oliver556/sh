#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 全局环境变量与常量配置
# @名称:         lib/env.sh
# @职责:         定义全局通用的代理地址、仓库路径及静态配置
# ============================================================

# ------------------------------
# 1. 基础元数据
# ------------------------------
AUTHOR="Jamison"
PROJECT_NAME="VpsScriptKit"
GITHUB_URL="https://github.com/oliver556/sh"

# ------------------------------
# 2. 网络与仓库配置
# ------------------------------
# 全局 GitHub 代理地址
GH_PROXY="https://github.viplee.top/"

# 远程仓库标识
REPO="oliver556/sh"

# 默认分支
# BRANCH="main"

# 安装路径
INSTALL_DIR="/opt/VpsScriptKit"

# ------------------------------
# 3. 远程资源路径拼接 (示例)
# ------------------------------
# 远程原始文件基础路径 (raw.githubusercontent.com)
# RAW_URL_BASE="raw.githubusercontent.com/${REPO}/${BRANCH}"

# 结合代理后的下载地址前缀
# REMOTE_BASE_URL="${GH_PROXY}${RAW_URL_BASE}"

# ------------------------------
# 4. 其它全局开关 (可选)
# ------------------------------
# 是否开启 Debug 模式 (1为开启，0为关闭)
# DEBUG_MODE=0

# 检查更新的间隔时间 (秒)
# CHECK_UPDATE_INTERVAL=86400

# 重装成功后的自动重启倒计时 (秒)
REBOOT_DELAY=3

# 系统重装大概耗时（分）
INSTALL_ESTIMATE_TIME=15