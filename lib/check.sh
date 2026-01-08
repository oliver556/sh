#!/usr/bin/env bash
### ============================================================
# VpsScriptKit - 通用检测工具 - 函数库
#
# 职责：
# - 只提供“判断”，不做任何操作
### ============================================================

# ------------------------------
# 判断当前用户是否为 root
# @调用示例:
#   if is_root; then
#       echo "权限检查通过"
#   else
#       echo "请切换到 root 用户执行"
#   fi
# ------------------------------
is_root() {
  # id -u 返回当前用户 UID
  # root 的 UID 固定为 0
  [[ "$(id -u)" -eq 0 ]]
}

# ------------------------------
# 判断指定的命令是否存在于系统 PATH 中
# ------------------------------
# @参数: $1 - 命令名称 (如 wget, curl, git)
# @返回: 0 (存在), 1 (不存在)
# @调用示例:
#   if check_cmd "curl"; then
#       curl -I https://google.com
#   fi
check_cmd() {
  local cmd_name="$1"
  if command -v "$cmd_name" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# ------------------------------
# 判断 wget 是否已安装
# ------------------------------
# @描述: 这是一个基于 check_cmd 的语义化封装
# @返回: 0 (已安装), 1 (未安装)
# @调用示例:
#   if is_wget_installed; then
#       echo "wget 已就绪"
#   else
#       echo "正在安装 wget..."
#       apt install -y wget
#   fi
is_wget_installed() {
  check_cmd "wget"
}

# ------------------------------
# 判断是否为 Debian/Ubuntu 系统
# ------------------------------
# @返回: 0 (是), 1 (否)
# @调用示例:
#   if is_debian_series; then
#       apt update
#   fi
is_debian_series() {
  [[ -f /etc/debian_version ]]
}

# ------------------------------
# 判断是否为 RedHat/CentOS 系统
# ------------------------------
is_rhel_series() {
  [[ -f /etc/redhat-release ]]
}

# ------------------------------
# 确保 wget 已安装 (不存在则自动安装)
# ------------------------------
# @描述: 自动识别系统架构并补全环境
# @调用示例:
#   ensure_wget
#   wget https://example.com/file.sh
# ------------------------------
ensure_wget() {
  if is_wget_installed; then
    return 0
  fi

  # 只有在需要 ui 输出时才调用 ui 相关函数，否则直接 echo
  if declare -f ui_info > /dev/null; then
    ui_info "检测到 wget 未安装，正在尝试自动补全环境..."
  else
    ui_error "检测到 wget 未安装，正在尝试自动补全环境..."
  fi

  if is_debian_series; then
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y wget > /dev/null 2>&1
  elif is_rhel_series; then
    yum install -y wget > /dev/null 2>&1
  else
    # 兜底方案，直接尝试安装
    apt install -y wget || yum install -y wget || dnf install -y wget
  fi

  # 二次检查是否安装成功
  if is_wget_installed; then
    return 0
  else
    if declare -f ui_error > /dev/null; then
        ui blank
        ui_error "wget 安装失败，请手动检查网络或源设置。"
    else
        echo "Error: wget 安装失败。"
    fi
    return 1
  fi
}