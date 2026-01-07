#!/usr/bin/env bash

# tools 模块占位文件
module_entry() {
  ui clear
  ui print page_header_full "🚧 脚本工具 模块占位"
  echo "此模块尚未开发，按任意键返回主菜单"
  ui pause
  return
}
