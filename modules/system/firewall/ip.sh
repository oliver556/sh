#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 指定 IP 黑白名单管理
#
# @文件路径: modules/system/firewall/ip.sh
# @功能描述: 针对单个 IP/CIDR 的精准放行与封禁
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-24
# ==============================================================================

# ******************************************************************************
# 引入依赖模块
# ******************************************************************************
# shellcheck disable=SC1091
source "${BASE_DIR}/modules/system/firewall/utils.sh"

# ------------------------------------------------------------------------------
# 核心逻辑: 添加 IP 规则 (自动去重)
# ------------------------------------------------------------------------------
_add_ip_rule() {
    local target="$1" # ACCEPT 或 DROP
    shift
    local ips=("$@")

    if [ ${#ips[@]} -eq 0 ]; then
        print_error "未指定 IP 地址"
        return 1
    fi

    # 确保 iptables 已安装
    if ! command -v iptables >/dev/null 2>&1; then
        pkg_install "iptables" || return 1
    fi

    for ip in "${ips[@]}"; do
        # 1. 简单校验 IP 格式 (防止空输入)
        if [[ -z "$ip" ]]; then continue; fi

        # 2. 清理旧规则 (防止冲突：比如先把 IP 封了，现在又要放行，得先把封禁删掉)
        # 删除所有针对该 IP 的 INPUT 规则 (无论 ACCEPT 还是 DROP)
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
        iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
        
        # 3. 添加新规则
        # 插入到第 1 行，确保优先级最高 (比 GeoIP 和端口规则都优先)
        iptables -I INPUT 1 -s "$ip" -j "$target"
        
        if [[ "$target" == "ACCEPT" ]]; then
            print_success "已添加白名单 IP: $ip (优先放行)"
        else
            print_success "已添加黑名单 IP: $ip (优先拒绝)"
        fi
    done

    # 4. 持久化保存
    _iptables_save_persistence
}

# ------------------------------------------------------------------------------
# 核心逻辑: 移除 IP 规则
# ------------------------------------------------------------------------------
_remove_ip_rule() {
    local ips=("$@")
    
    if [ ${#ips[@]} -eq 0 ]; then
        print_error "未指定要移除的 IP"
        return 1
    fi

    for ip in "${ips[@]}"; do
        local found=0
        if iptables -D INPUT -s "$ip" -j DROP 2>/dev/null; then
            print_success "已移除黑名单规则: $ip"
            found=1
        fi
        if iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null; then
            print_success "已移除白名单规则: $ip"
            found=1
        fi
        
        if [[ "$found" -eq 0 ]]; then
            print_warn "未找到关于 IP [$ip] 的任何规则"
        fi
    done

    _iptables_save_persistence
}

# ------------------------------------------------------------------------------
# 核心逻辑: 查看 IP 规则
# ------------------------------------------------------------------------------
firewall_list_ips() {
    print_echo "${BOLD_CYAN}当前手动添加的 IP 规则 (Input Chain Top Rules):${NC}"
    print_line
    
    # 筛选 INPUT 链中包含具体 IP (source != 0.0.0.0/0) 的规则
    # 排除掉 ipset, docker 等复杂规则
    local content
    content=$(iptables -S INPUT | grep -E "\-s [0-9]" | grep -v "match-set" | awk '{
        if ($0 ~ /DROP/) type="\033[31m[黑名单]\033[0m"
        else if ($0 ~ /ACCEPT/) type="\033[32m[白名单]\033[0m"
        else type="[其他]"
        
        # 提取 -s 后的 IP
        for(i=1;i<=NF;i++) if($i=="-s") ip=$(i+1)
        
        printf " %-20s %s\n", type, ip
    }')

    if [[ -n "$content" ]]; then
        echo -e "$content"
    else
        print_info "暂无手动添加的 IP 规则"
    fi
}

# ------------------------------------------------------------------------------
# UI 启动函数 (Start Wrappers)
# ------------------------------------------------------------------------------

firewall_allow_ip() {
    local ips=("$@")
    _add_ip_rule "ACCEPT" "${ips[@]}"
}

# 6. 白名单
firewall_start_allow_ip() {
    print_clear;
    print_box_info -s start -m "添加 IP 白名单 (放行)"
    print_echo "请输入要放行的 IP 或 IP段 (如 1.2.3.4 或 192.168.1.0/24)（输入 0 退出）"
    
    local input
    input=$(read_choice -s 1 -m "IP 地址 (空格分隔)")
    if [[ -z "$input" || "$input" == "0" ]] ; then
        print_info -m "操作已取消"
        return 0
    fi
    
    read -r -a ips <<< "$input"
    print_line
    firewall_allow_ip "${ips[@]}"
    return 0
}


firewall_deny_ip() {
    local ips=("$@")
    _add_ip_rule "DROP" "${ips[@]}"
}

# 7. 黑名单
firewall_start_deny_ip() {
    print_clear;
    print_box_info -s start -m "添加 IP 黑名单 (封禁)"
    print_echo "请输入要封禁的 IP 或 IP段 (如 1.2.3.4)"
    
    local input
    input=$(read_choice -s 1 -m "IP 地址 (空格分隔)")
    if [[ -z "$input" || "$input" == "0" ]] ; then
        print_info -m "操作已取消"
        return 0
    fi
    
    read -r -a ips <<< "$input"
    print_line
    firewall_deny_ip "${ips[@]}"
    return 0
}

firewall_remove_ip() {
    local ips=("$@")
    _remove_ip_rule "${ips[@]}"
}

# 8. 清除规则
firewall_start_remove_ip() {
    print_clear;
    print_box_info -s start -m "清除指定 IP 规则"
    print_echo "将同时移除该 IP 的黑名单或白名单规则"
    
    local input
    input=$(read_choice -s 1 -m "IP 地址 (空格分隔)")
    if [[ -z "$input" || "$input" == "0" ]] ; then
        print_info -m "操作已取消"
        return 0
    fi
    
    read -r -a ips <<< "$input"
    print_line
    firewall_remove_ip "${ips[@]}"
    return 0
}

# 9. 查看规则
firewall_start_list_ips() {
    print_clear; print_box_info -m "IP 名单预览"
    firewall_list_ips
    # 只要查看了，就返回 0 以便外部等待
    return 0
}

# ------------------------------------------------------------------------------
# 核心逻辑: 清空所有手动 IP 规则 (一键复位)
# ------------------------------------------------------------------------------
firewall_flush_ips() {
    print_step "正在清空所有手动添加的 IP 规则..."
    
    # 1. 找出所有手动 IP 规则
    # 逻辑: 匹配 "-s 数字" (常规 IP) 且不含 "match-set" (排除 ipset/国家规则) 的 INPUT 规则
    local rules_to_delete
    rules_to_delete=$(iptables -S INPUT | grep -E "\-s [0-9]" | grep -v "match-set")
    
    if [[ -z "$rules_to_delete" ]]; then
        print_info "当前没有手动添加的 IP 规则，无需清理。"
        _iptables_save_persistence
        return 0
    fi

    # 2. 循环删除
    # 使用 sed 把 -A (Add) 变成 -D (Delete) 然后执行
    echo "$rules_to_delete" | sed 's/-A/-D/' | while read -r rule; do
        # 提取 IP 用于显示 (简单的文本处理)
        local ip_info
        ip_info=$(echo "$rule" | grep -oE "\-s [0-9\./]+")
        print_info "  - 移除规则: $ip_info"
        iptables "$rule" 2>/dev/null
    done

    # 3. 保存
    _iptables_save_persistence
    print_success "已清空所有手动 IP 黑白名单。"
}

# 10. 清空所有
firewall_start_flush_ips() {
    print_clear; print_box_info -m "清空所有 IP 名单"
    print_echo "${RED}警告：此操作将移除所有手动添加的 IP 白名单和黑名单规则！${NC}"
    print_echo "(注：不会影响 15-19 号的国家级封禁规则)"
    
    local confirm
    confirm=$(read_choice -s 1 -m "确认清空? [yes/no]")

    if [[ "$confirm" != "yes" ]] ; then
        print_info -m "操作已取消"
        return 0
    fi
    
    print_line
    firewall_flush_ips
    return 0
}