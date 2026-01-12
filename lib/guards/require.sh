#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 交互辅助函数
# 
# @文件路径: lib/guards/require.sh
# @功能描述: 强制满足（会修复）
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-12
# ==============================================================================

require_cmd() {
  local cmd="$1"

  if has_cmd "$cmd"; then
    return 0
  fi

  ui_warn "未检测到命令: $cmd，正在尝试安装..."

  install_cmd "$cmd" || {
    ui_error "安装 $cmd 失败"
    return 1
  }

  return 0
}
