#!/usr/bin/env bash

# tools 模块占位文件
module_entry() {
  print_clear
  ui print page_header "🚧 脚本工具 模块占位"
  echo "此模块尚未开发，按任意键返回主菜单"
  ui_wait
  return
}
