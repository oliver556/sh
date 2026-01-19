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
export VSK_VERSION
VSK_VERSION=$(cat "${BASE_DIR}/version" 2>/dev/null || echo "Unknown")

# ******************************************************************************
# 图标定义
# ******************************************************************************
# -r: 代表 readonly (只读)
# -x: 代表 export (导出环境变量)

# 引导图标
declare -rx ICON_NAV="▶"            # 引导
declare -rx ICON_TRIANGLE="▲"       # 引导2
declare -rx ICON_OK="✓"             # 成功 (成功提示)
declare -rx ICON_FAIL="✗"           # 失败 (错误提示)
declare -rx ICON_WARNING="⚠"        # 警告 (警告提示)
declare -rx ICON_ARROW="➜"          # 箭头 (输入引导)
declare -rx ICON_STAR="★"           # 星星 (亮点功能)
declare -rx ICON_GEAR="⚙"           # 齿轮 (核心配置)
declare -rx ICON_TIP="✦"            # 小贴士 (额外建议)
declare -rx ICON_EXIT="■"           # 结束退出 (运行终止)
declare -rx ICON_INFO="●"           # 实心圆点 (信息提示)
declare -rx ICON_LIGHTNING="⚡"      # 闪电

# 菜单栏图标
declare -rx ICON_HOME="▣"           # 首页
declare -rx ICON_UPDATE="↻"         # 系统更新 
declare -rx ICON_MAINTAIN="⚒"       # 系统工具
declare -rx ICON_DOCKER="☵"         # Docker
declare -rx ICON_SWAP="▥"           # Swap
declare -rx ICON_NODE="⑆"           # 节点搭建
declare -rx ICON_TEST="⧗"           # 测试脚本

# # ******************************************************************************
# # 颜色定义
# # ******************************************************************************
# # shellcheck disable=SC2155
# {
#     declare -rx RED=$(tput setaf 1)       # 红色 (错误/危险)
#     declare -rx GREEN=$(tput setaf 2)     # 绿色 (成功/通过)
#     declare -rx YELLOW=$(tput setaf 3)    # 黄色 (警告/注意)
#     declare -rx BLUE=$(tput setaf 4)      # 蓝色 (信息/普通)
#     declare -rx PURPLE=$(tput setaf 5)    # 紫色 (强调/特殊)
#     declare -rx CYAN=$(tput setaf 6)      # 青色 (调试/路径)
#     declare -rx WHITE=$(tput setaf 7)     # 白色 (正文)
#     declare -rx GREY=$(tput setaf 8)     # 灰色 (正文)

#     declare -rx BOLD=$(tput bold)         # 加粗 (用于标题/重点)
#     declare -rx DIM=$(tput dim)           # 暗淡 (用于次要信息/注释)
#     declare -rx NC=$(tput sgr0)           # 重置 (No Color，清除所有格式)

#     # 组合样式
#     declare -rx BOLD_RED="${BOLD}${RED}"
#     declare -rx BOLD_GREEN="${BOLD}${GREEN}"
#     declare -rx BOLD_YELLOW="${BOLD}${YELLOW}"
#     declare -rx BOLD_BLUE="${BOLD}${BLUE}"
#     declare -rx BOLD_CYAN="${BOLD}${CYAN}"
#     declare -rx BOLD_WHITE="${BOLD}${WHITE}"
#     declare -rx BOLD_GREY="${BOLD}${GREY}"
# }

# ******************************************************************************
# 支持的系统版本
# ******************************************************************************
declare -rx SUPPORTED_DEBIAN="10 11 12 13"
declare -rx SUPPORTED_UBUNTU="16.04 18.04 20.04 22.04 24.04"

# ******************************************************************************
# 基础常量定义
# ******************************************************************************
declare -rx SINSTALL_DIR="/opt/VpsScriptKit"                                        # 安装目录
declare -rx BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"             # 项目根目录
declare -rx PROJECT_NAME="VpsScriptKit"                                             # 项目名称
declare -rx REPO="oliver556/sh"                                                     # GitHub 仓库
declare -rx BRANCH="main"                                                           # GitHub 分支
declare -rx GH_PROXY="https://github.viplee.cc/"                                    # GitHub 代理地址
declare -rx GITHUB_URL="https://github.com/${REPO}/${BRANCH}"                       # GitHub 地址
declare -rx GITHUB_RAW="${GH_PROXY}raw.githubusercontent.com/${REPO}/${BRANCH}"     # GitHub Raw 地址

# ******************************************************************************
# 核心库统一加载 (Loader)
# ******************************************************************************
# 定义核心库列表（加载顺序至关重要，env 定义常量，utils 提供基础工具，ui 提供界面）
LIBS=(
    # 核心基础库
    "os.sh"              # 系统识别
    "color.sh"           # 颜色定义
    "ui.sh"              # UI 渲染 (依赖颜色定义)
    "print.sh"
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