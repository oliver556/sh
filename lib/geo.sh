#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - ISP / 地理位置
#
# @文件路径: lib/geo.sh
# @功能描述: 提供 ISP / 地理位置
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: net_get_isp
# 功能:   获取 ISP / 运营商
# 
# 参数:
#   无
# 
# 返回值:
#   成功: ISP / 运营商
#   失败: N/A
# 
# 示例:
#   net_get_isp
# ------------------------------------------------------------------------------
net_get_isp() {
    # 使用 ipinfo.io JSON 接口获取 ISP
    curl -s https://ipinfo.io/org || echo "N/A"
}

# ------------------------------------------------------------------------------
# 函数名: net_get_geo
# 功能:   获取获取地理位置
# 
# 参数:
#   无
# 
# 返回值:
#   成功: 地理位置
#   失败: 未获取到地理位置
# 
# 示例:
#   net_get_geo
# ------------------------------------------------------------------------------
net_get_geo() {
    local ipinfo country city
    
    # 方案 1: 使用 ip-api.com (该接口无需 API Key，稳定性极高)
    # 格式为: 国家代码,城市名
    ipinfo=$(curl -s --max-time 3 "http://ip-api.com/line/?fields=countryCode,city")
    
    if [[ -n "$ipinfo" && $(echo "$ipinfo" | wc -l) -eq 2 ]]; then
        # 结果转换为单行输出，例如: US Los Angeles
        echo "$ipinfo" | tr '\n' ' ' | sed 's/ $//'
        return 0
    fi

    # 方案 2: 使用 ipinfo.io (作为备选)
    ipinfo=$(curl -s --max-time 3 https://ipinfo.io/json)
    if [[ -n "$ipinfo" ]]; then
        country=$(echo "$ipinfo" | sed -n 's/.*"country": "\(.*\)".*/\1/p')
        city=$(echo "$ipinfo" | sed -n 's/.*"city": "\(.*\)".*/\1/p')
        
        if [[ -n "$country" && -n "$city" ]]; then
            echo "${country} ${city}"
            return 0
        fi
    fi

    echo "未获取到地理位置"
    return 1
}