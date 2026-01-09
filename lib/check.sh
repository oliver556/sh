#!/usr/bin/env bash
### ============================================================
# VpsScriptKit - 通用检测工具 - 函数库
#
# 职责：
# - 只提供“判断”，不做任何操作
### ============================================================

# ---------------------------------------------------------------------------------
# 基础命令与权限检测
# ---------------------------------------------------------------------------------

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
# 判断当前用户是否为 root
# @调用示例:
#   if is_root; then
#     echo "权限检查通过"
#   else
#     echo "请切换到 root 用户执行"
#   fi
# ------------------------------
is_root() {
  [ "$(id -u)" -eq 0 ]
}

# ------------------------------
# 辅助函数: 是否为 root，返回提示
# ------------------------------
check_root() {
  is_root && return 0
  ui_error "该功能需要使用 root 用户才能运行此脚本"
  ui blank
  ui_tip "请切换到 'root' 用户来执行。"
  ui_wait_enter
  return 1
}

# 判断是否为 Debian/Ubuntu 系列
is_debian_series() {
    [[ -f /etc/debian_version ]]
}

# 判断是否为 RedHat/CentOS 系列
is_rhel_series() {
    [[ -f /etc/redhat-release ]]
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

# =================================================================================
# Docker 进阶检测与自动安装逻辑
# =================================================================================

# 检查 Docker 是否已安装
docker_is_installed() {
    check_cmd "docker"
}

# 检查 Docker Compose 是否就绪 (同时支持新版插件模式和旧版独立模式)
docker_compose_is_installed() {
    docker compose version >/dev/null 2>&1 || check_cmd "docker-compose"
}

# ---------------------------------------------------------------------------------
# 函数: install_docker_logic
# 描述: 安装/更新 Docker (底层 Worker)  (默认直连官方源，中国用户自动加速)
# ---------------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------------
# 函数: start_and_enable_docker
# 描述: 启动 Docker 并设置开机自启，可重载 daemon.json 配置
# 参数:
#   $1 可选 "restart" 表示强制重启 Docker
# ---------------------------------------------------------------------------------
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


# ------------------------------
# 使用 LinuxMirrors 脚本安装 (https://linuxmirrors.cn)
# ------------------------------
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

# ---------------------------------------------------------------------------------
# 函数: uninstall_docker_logic
# 描述: 纯粹的 Docker 卸载逻辑 (底层 Worker)
# ---------------------------------------------------------------------------------
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
