#!/usr/bin/env bash

# docker 模块占位文件
docker_entry() {
  ui clear
  ui print page_header_full "🚧 Docker 管理 模块占位"
  echo "此模块尚未开发，按任意键返回主菜单"
  ui pause
  return
}
