#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - Docker 安装
#
# @文件路径: modules/docker/install.sh
# @功能描述: 安装 docker
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: install_docker_logic
# 功能:   安装/更新 Docker (底层 Worker)  (默认直连官方源，中国用户自动加速)
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   install_docker_logic
# ------------------------------------------------------------------------------
install_docker_logic() {
  print_box_info -s start -m "安装 Docker 环境..."

  if get_supported_package_manager >/dev/null; then
        linuxmirrors_install_docker || {
            print_error -m "Docker 安装失败，请检查网络或系统配置"
            return 1
        }
    else
        # TODO 暂时先不处理 没有包的情况
        # install docker docker-compose
        print_warn -m "当前系统未检测到 apt/yum/dnf，暂不支持自动安装 Docker"
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
    print_step "开始启动并启用 Docker 服务..."

    # 启动 Docker
    if command -v systemctl &>/dev/null; then
        if sudo systemctl "${action}" docker && sudo systemctl enable docker; then
            print_box_success -s finish -m "安装 Docker 环境，成功启动并设置开机自启。"
        else
            ui_box_error "Docker 启动或启用失败！"
            return 1
        fi
    else
        # 老系统 fallback
        if sudo service docker start; then
            print_box_success -s finish -m "安装 Docker 环境，成功启动并设置开机自启 (service 方式)。"
        else
            print_box_error -m "Docker 启动失败！"
            return 1
        fi
    fi

    # 如果 daemon.json 存在并且需要重载
    if [ -f /etc/docker/daemon.json ]; then
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl restart docker 2>/dev/null || sudo service docker restart 2>/dev/null
        pring_box_success -s finish -m "Docker 重载配置并重启。"
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
    # local country
    # country=$(curl -s ipinfo.io/country || echo "UNKNOWN")

    local region
    region=$(net_region)

    if [ "$region" = "Global" ]; then
        print_step "网络环境检测: 国际互联 (Global)"
    else
        print_step "网络环境检测: 中国大陆 (CN)"
    fi

    local docker_script="https://linuxmirrors.cn/docker.sh"

    print_step "正在下载并执行 LinuxMirrors Docker 安装脚本..."

    # 中国镜像
    if [ "$region" = "CN" ]; then
        if ! curl -sSL "$docker_script" | bash -s -- \
            --source mirrors.huaweicloud.com/docker-ce \
            --source-registry docker.1ms.run \
            --protocol https \
            --use-intranet-source false \
            --install-latest true \
            --close-firewall false \
            --ignore-backup-tips; then
            print_error "Docker 安装脚本执行失败"
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
            print_error "Docker 安装脚本执行失败"
            return 1
        fi
    fi

  # 设置开机并自启
  start_and_enable_docker || return 1
}
