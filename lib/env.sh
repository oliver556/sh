#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 全局环境变量与常量配置
# 
# @文件路径: lib/env.sh
# @功能描述: 环境初始化、依赖加载、主菜单渲染与路由分发
#
# @作者:    Jamison
# @版本:    0.0.1
# @创建日期: 2026-01-011
# ==============================================================================

# ******************************************************************************
# 基础常量定义
# ******************************************************************************
# 安装目录
export INSTALL_DIR="/opt/VpsScriptKit"

# BASE_DIR: 项目根目录
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 项目名称
export PROJECT_NAME="VpsScriptKit"

# 远程仓库地址
export REPO="oliver556/sh"

# 默认分支
export BRANCH="main"

# 全局 GitHub 代理地址
export GH_PROXY="https://github.viplee.top/"

export RAW_URL_BASE="${GH_PROXY}raw.githubusercontent.com/${REPO}/${BRANCH}"

# 链接路径
export BIN_PATHS=(
    "/usr/local/bin/v"
    "/usr/local/bin/vsk"
    "/usr/bin/v"
    "/usr/bin/vsk"
)

# 支持的系统类型
export SUPPORTED_OS=("debian")

# 读取版本号 (从根目录 version 文件读取，方便自动更新同步) (如果文件不存在则默认 Unknown)
export VSK_VERSION=$(cat "${BASE_DIR}/version" 2>/dev/null || echo "Unknown")

# ******************************************************************************
# 核心库统一加载 (Loader)
# ******************************************************************************
# 定义核心库列表（加载顺序至关重要，env 定义常量，utils 提供基础工具，ui 提供界面）
LIBS=(
    # 核心基础库
    "os.sh"              # 系统识别
    "color.sh"           # 颜色定义
    "ui.sh"              # UI 渲染 (依赖颜色定义)
    "utils.sh"           # 全局通用工具 (最基础)
    "interact.sh"        # 交互逻辑 (依赖 UI)
    "check.sh"           # 环境检测 (依赖 UI 和 utils)
    "network.sh"         # 网络信息 & 统计
    "geo.sh"             # ISP / 地理位置
    "system.sh"          # 系统信息
    "router.sh"          # 路由分发 (依赖以上所有)
    # 辅助/守护库
    "guards/check.sh"    # 检查 + 提示（不修复）
    "guards/ensure.sh"   # 尝试安装保障（可失败）
    "guards/require.sh"  # 强制满足（会修复）
    "guards/network.sh"  # 网络状态检测
)

# 循环加载并检查，避免 source 不存在的文件导致报错退出
for lib in "${LIBS[@]}"; do
    if [[ -f "${BASE_DIR}/lib/$lib" ]]; then
        source "${BASE_DIR}/lib/$lib"
    fi
done

# ******************************************************************************
# 其它全局开关 (可选)
# ******************************************************************************
# 是否开启 Debug 模式 (1为开启，0为关闭)
# export DEBUG_MODE=0

# 检查更新的间隔时间 (秒)
# export CHECK_UPDATE_INTERVAL=86400

# 重装成功后的自动重启倒计时 (秒)
export REBOOT_DELAY=3

# 系统重装大概耗时（分）
export INSTALL_ESTIMATE_TIME=15