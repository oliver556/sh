#!/usr/bin/env bash
# 指定使用 env 查找 bash，保证在 macOS / Linux 上都能找到 bash

# ============================================================
# VpsScriptKit - Bootstrap 启动引导脚本
#
# 职责说明：
# 1. 解析项目真实路径（兼容软链接）
# 2. 定位项目根目录
# 3. 初始化全局目录变量
# 4. 加载 lib 中的通用工具
# 5. 做最基础、无破坏性的环境检查
#
# 重要约定：
# - 本文件不允许出现任何业务逻辑
# - 本文件必须是所有脚本的第一个 source 文件
# ============================================================

# ------------------------------
# Shell 安全选项（工程级）
# ------------------------------

set -o errexit
# 一旦有命令返回非 0，立即退出脚本，避免错误被忽略

set -o pipefail
# 管道中任意一段失败，整体失败，防止错误被吞掉

set -o nounset
# 使用未定义变量时直接报错，避免拼写错误导致隐蔽 bug

# ------------------------------
# 获取 bootstrap.sh 的真实路径
# ------------------------------

BOOTSTRAP_FILE="${BASH_SOURCE[0]}"
# BASH_SOURCE 在 source 时依然指向真实文件，是获取当前脚本路径的最佳方式

# 定义一个函数，用来解析软链接
# macOS 没有 readlink -f，因此必须手写
resolve_path() {
  local path="$1"        # 当前处理的路径

  # 当 path 是软链接时，循环解析
  while [ -L "$path" ]; do
    # 获取软链接所在目录的物理路径
    local dir
    dir="$(cd -P "$(dirname "$path")" && pwd)"

    # 读取软链接指向的目标
    path="$(readlink "$path")"

    # 如果是相对路径，补全为绝对路径
    [[ "$path" != /* ]] && path="$dir/$path"
  done

  # 返回最终真实文件所在的目录
  cd -P "$(dirname "$path")" && pwd
}

# core 目录路径（bootstrap.sh 所在目录）
CORE_DIR="$(resolve_path "$BOOTSTRAP_FILE")"

# 项目根目录（core 的上一级）
BASE_DIR="$(cd "$CORE_DIR/.." && pwd)"

# ------------------------------
# 定义全局只读路径变量
# ------------------------------

readonly VSK_BASE_DIR="$BASE_DIR"
# 项目根目录

readonly VSK_CORE_DIR="$BASE_DIR/core"
# 核心控制脚本目录

readonly VSK_LIB_DIR="$BASE_DIR/lib"
# 通用库目录

readonly VSK_MODULES_DIR="$BASE_DIR/modules"
# 功能模块目录

readonly VSK_CONFIG_DIR="$BASE_DIR/config"
# 配置文件目录

readonly VSK_DATA_DIR="$BASE_DIR/data"
# 状态 / 数据目录

readonly VSK_LOG_DIR="$BASE_DIR/logs"
# 日志目录

# ------------------------------
# 基础环境信息
# ------------------------------

readonly VSK_OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
# 获取操作系统类型：
# - linux
# - darwin（macOS）

readonly VSK_VERSION="$(cat "$BASE_DIR/version" 2>/dev/null || echo "unknown")"
# 从 version 文件读取当前版本
# 如果文件不存在，则返回 unknown（不直接报错）

# ------------------------------
# 加载通用库（顺序非常重要）
# ------------------------------

source "$VSK_LIB_DIR/utils.sh"
# 通用工具函数（最基础，最先加载）

source "$VSK_LIB_DIR/log.sh"
# 日志系统，后续所有模块都依赖

source "$VSK_LIB_DIR/ui.sh"
# 界面 / 输出相关函数

source "$VSK_LIB_DIR/check.sh"
# 系统 / 权限 / 软件检测函数

source "$VSK_LIB_DIR/env.sh"
# 环境相关检测（发行版、架构等）

# ------------------------------
# 确保必要目录存在
# ------------------------------

mkdir -p "$VSK_DATA_DIR"
# 创建数据目录（如果不存在）

mkdir -p "$VSK_LOG_DIR"
# 创建日志目录（如果不存在）

# ------------------------------
# 基础权限与系统校验
# ------------------------------

if is_root; then
  # 如果当前用户是 root
  export VSK_IS_ROOT=1
else
  # 如果不是 root
  export VSK_IS_ROOT=0
fi

# 校验操作系统是否受支持
case "$VSK_OS_TYPE" in
  linux|darwin)
    # 支持 Linux 和 macOS
    ;;
  *)
    # 其他系统直接退出
    echo "❌ Unsupported OS: $VSK_OS_TYPE"
    exit 1
    ;;
esac

# ------------------------------
# Debug 模式支持
# ------------------------------

# 使用方式：
# DEBUG=1 v
# DEBUG=1 bash core/main.sh

if [[ "${DEBUG:-0}" == "1" ]]; then
  # 打开 shell 执行追踪
  set -o xtrace
  export VSK_DEBUG=1
else
  export VSK_DEBUG=0
fi

# ------------------------------
# Bootstrap 完成标记
# ------------------------------

export VSK_BOOTSTRAPPED=1
# 用于防止被重复 source 或用于断言环境是否已初始化
