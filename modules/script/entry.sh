#!/usr/bin/env bash

# tools 模块占位文件
module_entry() {
  print_clear
  print_box_header "${ICON_GEAR}$(ui_spaces 1)脚本工具 模块占位"

  echo "此模块尚未开发，按任意键返回主菜单"
  ui_wait
  return
}
