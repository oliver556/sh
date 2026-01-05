#!/usr/bin/env bash

### ============================================================
# VpsScriptKit - 网络信息工具 - 函数库
# @名称:         network.sh
# @职责:
# - 提供获取宿主机网络相关信息内容
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2025-12-30
# @修改日期:     2025-01-04
#
# @许可证:       MIT
### ============================================================


# ------------------------------
# 获取公网 IPv4
# ------------------------------
net_get_ipv4() {
    local ip
    # 首选使用 https://ipinfo.io/ip，备选使用其他接口
    ip=$(curl -s4 --max-time 2 https://ipinfo.io/ip || curl -s4 --max-time 2 https://api64.ipify.org || curl -s4 --max-time 2 https://4.icanhazip.com)
    
    if [[ -z "$ip" ]]; then
        echo "未检测到公网 IPv4"
    else
        echo "$ip"
    fi
}

# ------------------------------
# 获取公网 IPv6
# ------------------------------
net_get_ipv6() {
    local ip
    # 尝试通过支持 IPv6 的接口获取，并保留您提供的 grep ':' 逻辑进行校验
    ip=$(curl -s6 --max-time 2 https://ipinfo.io/ip || curl -s6 --max-time 2 https://6.icanhazip.com || curl -s6 --max-time 2 https://4.icanhazip.com)
    
    if [[ "$ip" == *":"* ]]; then
        echo "$ip"
    else
        echo "未检测到公网 IPv6"
    fi
}

# ------------------------------
# 获取内网 IPv4
# ------------------------------
net_get_private_ipv4() {
    local ip
    ip=$(hostname -I 2>/dev/null | awk '{print $1}' | xargs)
    if [[ -z "$ip" ]]; then
        echo "未检测到内网 IPv4"
    else
        echo "$ip"
    fi
}

# ------------------------------
# 获取内网 IPv6
# ------------------------------
net_get_private_ipv6() {
    local ip
    # 优先获取网卡上的全局 IPv6 地址
    ip=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d'/' -f1 | head -n 1 | xargs)
    
    # 如果没找到全局地址，再找本地地址
    if [[ -z "$ip" ]]; then
        ip=$(ip -6 addr show | grep -E 'inet6 (fe80|fc00|fd00)' | awk '{print $2}' | cut -d'/' -f1 | head -n 1 | xargs)
    fi

    if [[ -z "$ip" ]]; then
        echo "未检测到内网 IPv6"
    else
        echo "$ip"
    fi
}

# ------------------------------
# 获取默认网关
# ------------------------------
net_get_gateway() {
    # 解析默认网关
    ip route | awk '/default/ {print $3}' || echo "N/A"
}

# ------------------------------
# 获取 DNS 服务器
# ------------------------------
net_get_dns() {
    # 从 /etc/resolv.conf 解析 DNS
    grep '^nameserver' /etc/resolv.conf | awk '{print $2}' || echo "N/A"
}

# ------------------------------
# 获取 ISP / 运营商
# ------------------------------
net_get_isp() {
    # 使用 ipinfo.io JSON 接口获取 ISP
    curl -s https://ipinfo.io/org || echo "N/A"
}

# ------------------------------
# 获取地理位置
# ------------------------------
net_get_geo() {
    local ipinfo
    # 获取完整的 json 用于拆分
    ipinfo=$(curl -s --max-time 2 https://ipinfo.io/json)
    
    if [[ -z "$ipinfo" ]]; then
        echo "未获取到地理位置"
        return
    fi

    # 按照您提供的逻辑拆分
    local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
    local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')

    if [[ -n "$country" && -n "$city" ]]; then
        # 输出格式：US Los Angeles
        echo "${country} ${city}" | xargs
    else
        echo "未获取到地理位置"
    fi
}


# ------------------------------
# 测试网络连通性
# ------------------------------
net_test_connectivity() {
    # 测试 8.8.8.8 是否可达
    if ping -c 1 -W 1 8.8.8.8 &>/dev/null; then
        echo "正常"
    else
        echo "异常"
    fi
}

# ------------------------------
# 内部工具：流量单位转换
# ------------------------------
_net_format_traffic() {
    local bytes=$1
    # 使用 awk 进行单位转换，保持两位小数
    awk -v b="$bytes" 'BEGIN {
        if (b < 1024) {
            printf "%.2fB", b
        } else if (b < 1048576) {
            printf "%.2fK", b/1024
        } else if (b < 1073741824) {
            printf "%.2fM", b/1048576
        } else {
            printf "%.2fG", b/1073741824
        }
    }'
}

# ------------------------------
# 获取总接收流量
# ------------------------------
net_get_total_rx() {
    # 统计所有网卡（排除 lo）的接收字节 (第2列)
    local total_rx
    total_rx=$(awk '/:/ {if($1 != "lo:") rx += $2} END {print rx}' /proc/net/dev)
    _net_format_traffic "${total_rx:-0}"
}

# ------------------------------
# 获取总发送流量
# ------------------------------
net_get_total_tx() {
    # 统计所有网卡（排除 lo）的发送字节 (第10列)
    local total_tx
    total_tx=$(awk '/:/ {if($1 != "lo:") tx += $10} END {print tx}' /proc/net/dev)
    _net_format_traffic "${total_tx:-0}"
}

# ------------------------------
# 获取 TCP 拥塞控制算法
# ------------------------------
net_get_congestion_control() {
    # 返回如 bbr, cubic, reno 等
    sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "N/A"
}

# ------------------------------
# 获取默认队列规程 (qdisc)
# ------------------------------
net_get_qdisc() {
    # 返回如 fq, fq_codel, noop 等
    sysctl -n net.core.default_qdisc 2>/dev/null || echo "N/A"
}