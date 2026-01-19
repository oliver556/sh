#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - Docker 卸载
#
# @文件路径: modules/docker/install.sh
# @功能描述: 卸载 docker
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: uninstall_docker_logic
# 功能:   纯粹的 Docker 卸载逻辑 (底层 Worker)
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   uninstall_docker_logic
# ------------------------------------------------------------------------------

uninstall_docker_logic() {
  print_clear

  print_box_info -s start -m "卸载 Docker 环境..."
 
  # 1. 停止所有容器
  print_step "正在停止并删除所有容器..."
  docker ps -a -q | xargs -r docker rm -f

  # 2. 删除镜像
  print_step "正在删除所有镜像..."
  docker images -q | xargs -r docker rmi

  # 3. 清理卷和网络
  print_step "正在清理未使用的卷和网络..."
  docker volume prune -f
  docker network prune -f

  # 4. 卸载 Docker 相关软件包
  print_step "正在卸载 Docker 软件包..."
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras docker docker-engine docker.io docker-compose

  # 5. 删除 Docker 数据目录（保险措施）
  print_step "正在删除残留数据目录..."
  sudo rm -rf /var/lib/docker /var/lib/containerd

  # 6. 删除配置文件和仓库
  print_step "正在清理配置文件和仓库..."
  sudo rm -f /etc/docker/daemon.json
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc

  # 7. 清理系统依赖并更新
  print_step "正在清理不需要的依赖并更新系统..."
  sudo apt-get autoremove -y
  sudo apt-get update

  # 8. 刷新 shell hash
  hash -r
  
  print_box_success -s finish "卸载 Docker 环境。"
}
