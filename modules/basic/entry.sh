#!/usr/bin/env bash

# 模块占位文件，不做实际操作
module_entry() {
  ui_clear
  ui print page_header_full "🚧 ${MODULE_NAME} 模块占位"
  echo "此模块尚未开发，按任意键返回主菜单"
  ui_pause
  return
}

# 定义模块名称（可在 router.sh 调用）
MODULE_NAME="基础工具"
