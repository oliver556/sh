#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - IPv4/IPv6 优先级管理
#
# @文件路径: modules/system/network/ipv_priority.sh
# @功能描述: 修改 /etc/gai.conf 以调整系统 DNS 解析时的 V4/V6 优先级
#
# @作者: Jamison
# @版本: 1.0.0
# ==============================================================================

# 定义全局缓存变量，避免每次刷新菜单都 curl 导致卡顿
G_IPV4_ADDR=""
G_IPV6_ADDR=""
G_NET_CHECKED=false

# ------------------------------------------------------------------------------
# 函数名: _init_network_check
# 功能:   预先检测网络状态 (缓存机制)
# ------------------------------------------------------------------------------
_init_network_check() {
    print_clear

    # 如果已经检测过，就不再检测，除非强制刷新
    if [[ "$G_NET_CHECKED" == "true" ]]; then return; fi
    
    # 检测 IPv4
    if command -v net_get_ipv4 &>/dev/null; then
        G_IPV4_ADDR=$(net_get_ipv4 2>/dev/null)
    else
        # 兜底逻辑 (万一没引入 lib/network.sh)
        G_IPV4_ADDR=$(curl -s4f https://api64.ipify.org 2>/dev/null)
    fi

    # 检测 IPv6
    if command -v net_get_ipv6 &>/dev/null; then
        G_IPV6_ADDR=$(net_get_ipv6 2>/dev/null)
    else
        # 兜底逻辑
        G_IPV6_ADDR=$(curl -s6f https://api64.ipify.org 2>/dev/null)
    fi

    G_NET_CHECKED=true
    print_clear
}

# ------------------------------------------------------------------------------
# 函数名: _check_ipv_priority
# 功能:   检测当前系统优先级配置
# ------------------------------------------------------------------------------
_check_ipv_priority() {
    if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
        echo "IPv4"
    else
        echo "IPv6"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: _draw_ipv_status
# 功能:   绘制优先级状态面板
# ------------------------------------------------------------------------------
_draw_ipv_status() {
    local priority
    priority=$(_check_ipv_priority)
    
    local display_priority="${GREY}检测中...${NC}"
    
    if [[ "$priority" == "IPv4" ]]; then
        display_priority="${GREEN}IPv4 优先${NC}"
    else
        display_priority="${BOLD_PURPLE}IPv6 优先 (默认)${NC}"
    fi

    # 格式化 IP 显示 (处理空值)
    local v4_show="${RED}未检测到${NC}"
    if [[ -n "$G_IPV4_ADDR" && "$G_IPV4_ADDR" != *"未检测到"* ]]; then
        v4_show="${GREEN}${G_IPV4_ADDR}${NC}"
    fi

    local v6_show="${RED}未检测到${NC}"
    if [[ -n "$G_IPV6_ADDR" && "$G_IPV6_ADDR" != *"未检测到"* ]]; then
        v6_show="${GREEN}${G_IPV6_ADDR}${NC}"
    fi

    # 第一行: 优先级状态
    print_status_item -l "当前优先级:" -v "${display_priority}" -w 12 -W 20
    print_status_done
    
    # 第二行: IPv4 地址
    print_status_item -l "公网 IPv4:" -v "${v4_show}" -w 12
    print_status_done

    # 第三行: IPv6 地址
    print_status_item -l "公网 IPv6:" -v "${v6_show}" -w 12
    print_status_done
    print_line
}

# ------------------------------------------------------------------------------
# 函数名: set_ipv4_prefer
# 功能:   设置 IPv4 优先
# ------------------------------------------------------------------------------
set_ipv4_prefer() {
    print_clear
    print_box_info -m "正在设置 IPv4 为优先网络..." -s start

    local gai_file="/etc/gai.conf"
    # 1. 检查文件创建是否成功
    if [[ ! -f "$gai_file" ]]; then 
        if ! touch "$gai_file"; then
            print_error -m "无法创建配置文件 $gai_file，权限不足？"
            return 1  # 返回非 0，表示失败
        fi
    fi

    if grep -q '^precedence ::ffff:0:0/96  100' "$gai_file"; then
        print_info -m "配置已存在，无需修改。"
    else
        print_step -m "写入优先级规则..."
        if ! echo 'precedence ::ffff:0:0/96  100' >> "$gai_file"; then
            print_error -m "写入配置失败！请检查磁盘空间或文件权限。"
            return 1  # 遇到错误，立即中断并返回失败状态
        fi
    fi

    print_box_success -m "设置完成！系统现在会优先使用 IPv4。"
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: set_ipv6_prefer
# 功能:   设置 IPv6 优先 (恢复默认)
# ------------------------------------------------------------------------------
set_ipv6_prefer() {
    print_clear
    print_box_info -m "正在恢复 IPv6 优先 (系统默认)..." -s start

    if [[ "$G_IPV6_ADDR" == *"未检测"* || -z "$G_IPV6_ADDR" ]]; then
        print_box_warn -m "警告: 当前未检测到公网 IPv6 地址"
        print_info -m "恢复默认优先级 (IPv6优先) 可能会导致网络请求先尝试 IPv6 而超时卡顿。"
        print_info -m "对于纯 IPv4 机器，建议保持 IPv4 优先。（输入 0 退出）"
        print_info -m  "我知道风险，仍然要恢复默认设置"
        
        if ! read_confirm; then
            return
        fi
        print_line
    fi

    local gai_file="/etc/gai.conf"

    if [[ -f "$gai_file" ]]; then
        print_step -m "移除 IPv4 优先规则..."
        sed -i '/^precedence ::ffff:0:0\/96  100/d' "$gai_file"
    else
        print_info -m "配置文件不存在，默认即为 IPv6 优先。"
    fi

    print_box_success -m "设置完成！已恢复系统默认优先级。"
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: run_ipv6_fix
# 功能:   调用外部修复脚本
# ------------------------------------------------------------------------------
run_ipv6_fix() {
    print_clear
    print_box_warn -m "即将运行第三方 IPv6 修复脚本"
    print_info -m "来源: jhb.ovh"
    print_info -m "功能: 尝试自动修复/添加 VPS 的 IPv6 网络配置（输入 0 退出）"
    
    if read_confirm -m "确认继续？(y|n)"; then
        print_line
        bash <(curl -L -s jhb.ovh/jb/v6.sh)
        
        # 修复完后强制刷新一下缓存，看看有没有获取到 IP
        G_NET_CHECKED=false
        
        print_line
        print_box_success -m "脚本执行结束"
        print_wait_enter
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ipv_priority_menu
# 功能:   主菜单
# ------------------------------------------------------------------------------
ipv_priority_menu() {
    check_root || return
    print_clear

    run_step -S 2 -m "正在检测网络连通性 (IPv4/IPv6)..." _init_network_check

    while true; do
        print_clear
        print_box_header "网络优先级设置 (IPv4/IPv6 Priority)"
        
        print_line
        _draw_ipv_status

        print_step -m "功能说明"
        print_info -m "调整系统 DNS 解析偏好 (/etc/gai.conf)"
        print_info -m "若拥有双栈 IP 但想强制走 IPv4 流量，请选择 1"
        
        print_line
        print_menu_item -p 0 -i 1 -s 2 -m "IPv4 优先"
        print_menu_item -p 0 -i 2 -s 2 -m "IPv6 优先 (恢复系统默认)"
        print_line
        print_menu_item -p 0 -i 3 -s 2 -m "IPv6 修复工具 (第三方)"
        
        print_line
        print_menu_item -p 0 -i 9 -s 2 -m "刷新 IP 检测"

        print_menu_go_level

        local choice
        choice=$(read_choice)

        case "$choice" in
            1) if set_ipv4_prefer; then print_wait_enter; fi ;;
            2) if set_ipv6_prefer; then print_wait_enter; fi ;;
            3) run_ipv6_fix ;;
            9) 
                G_NET_CHECKED=false
                _init_network_check 
                ;;
            0) return ;;
            *) print_error -m "无效选项" ;;
        esac
    done
}