#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 通用检测工具
#
# @文件路径: lib/check.sh
# @功能描述: 负责 “查” (环境检测、软件检测、依赖安装)
#
# 设计原则：
# - 只提供“判断”，不做任何操作
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-06
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: is_root
# 功能:   判断当前用户是否为 root
# 
# 参数: 无
# 
# 返回值: 
#    0 - root
#   !0 - 非 root
# 
# 示例:
#   is_root
# ------------------------------------------------------------------------------
is_root() {
  [ "$(id -u)" -eq 0 ]
}

# ------------------------------------------------------------------------------
# 函数名: has_cmd
# 功能:   判断指定的命令是否存在于系统 PATH 中
# 
# 参数:
#   $1 (string): 命令名称 (如 wget, curl, git) (必填)
# 
# 返回值:
#   0 - [成功时的含义]
#   1 - [失败时的含义]
# 
# 示例:
#   if has_cmd "curl"; then
#       curl -I https://google.com
#   fi
# ------------------------------------------------------------------------------
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# ******************************************************************************
# Docker 进阶检测与自动安装逻辑
# ******************************************************************************

# 检查 Docker 是否已安装
docker_is_installed() {
    has_cmd "docker"
}

# 检查 Docker Compose 是否就绪 (同时支持新版插件模式和旧版独立模式)
docker_compose_is_installed() {
    docker compose version >/dev/null 2>&1 || has_cmd "docker-compose"
}

# ------------------------------------------------------------------------------
# 函数名: install_docker_logic
# 功能:   安装/更新 Docker (底层 Worker)  (默认直连官方源，中国用户自动加速)
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   install_docker_logic
# ------------------------------------------------------------------------------
install_docker_logic() {
  ui_info "正在安装 Docker 环境..."

  if get_supported_package_manager; then
        linuxmirrors_install_docker || {
            ui_error "Docker 安装失败，请检查网络或系统配置"
            return 1
        }
    else
        # 暂时先不处理 没有包的情况
        # install docker docker-compose
        ui_warn "当前系统未检测到 apt/yum/dnf，暂不支持自动安装 Docker"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: start_and_enable_docker
# 功能:   启动 Docker 并设置开机自启，可重载 daemon.json 配置
# 
# 参数:
#   $1 (string): 可选 "restart" 表示强制重启 Docker (可选)
# 
# 返回值: 无
# 
# 示例:
#   start_and_enable_docker
# ------------------------------------------------------------------------------
start_and_enable_docker() {
    local action=${1:-start}
    ui_info "====== 启动并启用 Docker 服务======"
    
    # 启动 Docker
    if sudo systemctl start docker && sudo systemctl enable docker; then
        ui_success "Docker 已成功启动并设置开机自启。"
    else
        ui_error "Docker 启动或启用失败！"
        return 1
    fi

    if command -v systemctl &>/dev/null; then
        if sudo systemctl "${action}" docker && sudo systemctl enable docker; then
            ui_success "Docker 已成功启动并设置开机自启。"
        else
            ui_error "Docker 启动或启用失败！"
            return 1
        fi
    else
        # 老系统 fallback
        if sudo service docker start; then
            ui_success "Docker 已成功启动 (service 方式)。"
        else
            ui_error "Docker 启动失败！"
            return 1
        fi
    fi

    # 如果 daemon.json 存在并且需要重载
    if [ -f /etc/docker/daemon.json ]; then
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || sudo service docker restart 2>/dev/null
        ui_info "Docker 服务已重载配置并重启。"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 函数名: linuxmirrors_install_docker
# 功能:   使用 LinuxMirrors 脚本安装 (https://linuxmirrors.cn)
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   linuxmirrors_install_docker
# ------------------------------------------------------------------------------
linuxmirrors_install_docker() {
  # 获取国家地区
  local country
  country=$(curl -s ipinfo.io/country || echo "UNKNOWN")

  local docker_script="https://linuxmirrors.cn/docker.sh"

  ui_info "开始下载并执行 LinuxMirrors Docker 安装脚本..."

  # 中国镜像
  if [ "$country" = "CN" ]; then
    if ! curl -sSL "$docker_script" | bash -s -- \
        --source mirrors.huaweicloud.com/docker-ce \
        --source-registry docker.1ms.run \
        --protocol https \
        --use-intranet-source false \
        --install-latest true \
        --close-firewall false \
        --ignore-backup-tips; then
        ui_error "Docker 安装脚本执行失败"
        return 1
    fi
  else
    # 官方源
    if ! curl -sSL "$docker_script" | bash -s -- \
        --source download.docker.com \
        --source-registry registry.hub.docker.com \
        --protocol https \
        --use-intranet-source false \
        --install-latest true \
        --close-firewall false \
        --ignore-backup-tips; then
        ui_error "Docker 安装脚本执行失败"
        return 1
    fi
  fi

  # 设置开机并自启
  start_and_enable_docker || return 1
}

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
  ui line
  ui_success "====== 开始卸载 Docker======"

  # 1. 停止所有容器
  ui_info "--> 正在停止并删除所有容器..."
  docker ps -a -q | xargs -r docker rm -f

  # 2. 删除镜像
  ui_info "--> 正在删除所有镜像..."
  docker images -q | xargs -r docker rmi

  # 3. 清理卷和网络
  ui_info "--> 正在清理未使用的卷和网络..."
  docker volume prune -f
  docker network prune -f

  # 4. 卸载 Docker 相关软件包
  ui_info "--> 正在卸载 Docker 软件包..."
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras docker docker-engine docker.io docker-compose

  # 5. 删除 Docker 数据目录（保险措施）
  ui_info "--> 正在删除残留数据目录..."
  sudo rm -rf /var/lib/docker /var/lib/containerd

  # 6. 删除配置文件和仓库
  ui_info "--> 正在清理配置文件和仓库..."
  sudo rm -f /etc/docker/daemon.json
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc

  # 7. 清理系统依赖并更新
  ui_info "--> 正在清理不需要的依赖并更新系统..."
  sudo apt-get autoremove -y
  sudo apt-get update

  # 8. 刷新 shell hash
  hash -r
  ui line
  ui_success "====== Docker 环境已卸载。======"
  ui line
}
