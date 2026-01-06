#!/usr/bin/env bash

# node 模块占位文件
node_entry() {
  ui_clear
  ui print page_header_full "🚧 节点搭建脚本 模块占位"
  echo "此模块尚未开发，按任意键返回主菜单"
  ui pause
  return
}
