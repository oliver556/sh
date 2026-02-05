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
# [前置守卫] 环境依赖检查 (文件加载即执行，优先级最高)
# ------------------------------------------------------------------------------
_check_environment() {
    # 检查 iptables 命令是否存在
    if ! command -v iptables >/dev/null 2>&1; then
        print_warn "检测到核心组件 iptables 缺失，正在尝试自动安装..."
        
        # 尝试安装
        if ! pkg_install "iptables"; then
            print_error "致命错误: 无法安装 iptables，IP 管理模块停止加载。"
            return 1
        fi
        
        print_success "iptables 已安装。"
    fi
    
    # 可以在这里增加其他检查，比如 ipset 等
    return 0
}

# ==============================================================================
# 立即执行检查！
# 如果此步骤失败 (return 1)，脚本将在此处停止加载 (return 1)，
# 后续的所有函数定义都不会被执行，从而完美实现“不满足就没机会走”。
# ==============================================================================
_check_environment || return 1

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

    # 依赖检查
    # 如果后端判定为 iptables，则必须确保 iptables 命令存在
    if [[ "$backend" == "iptables" ]]; then
        if ! command -v iptables >/dev/null 2>&1; then
            print_warn "检测到 iptables 命令缺失，正在自动安装..."
            pkg_install "iptables" || return 1
        fi
    fi

    local backend
    backend=$(_get_firewall_backend)
    print_info "当前防火墙后端: ${BOLD_GREEN}${backend}${NC}"

    for ip in "${ips[@]}"; do
        # 1. 简单校验 IP 格式 (防止空输入)
        if [[ -z "$ip" ]]; then continue; fi

        case "$backend" in
            ufw)
                # UFW 逻辑
                # 先清理旧规则 (防止冲突)
                ufw delete allow from "$ip" >/dev/null 2>&1
                ufw delete deny from "$ip" >/dev/null 2>&1
                
                if [[ "$target" == "ACCEPT" ]]; then
                    ufw allow from "$ip" to any >/dev/null 2>&1
                    print_success "UFW: 已放行 IP $ip"
                else
                    # UFW deny 默认是 reject，这里显式用 deny
                    ufw deny from "$ip" to any >/dev/null 2>&1
                    print_success "UFW: 已封禁 IP $ip"
                fi
                ;;

            firewalld)
                # Firewalld 逻辑 (使用 rich-rule)
                # 先移除旧规则
                firewall-cmd --zone=public --remove-rich-rule="rule family='ipv4' source address='$ip' accept" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --remove-rich-rule="rule family='ipv4' source address='$ip' drop" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --remove-rich-rule="rule family='ipv4' source address='$ip' reject" --permanent >/dev/null 2>&1
                
                if [[ "$target" == "ACCEPT" ]]; then
                    firewall-cmd --zone=public --add-rich-rule="rule family='ipv4' source address='$ip' accept" --permanent >/dev/null 2>&1
                    print_success "Firewalld: 已放行 IP $ip"
                else
                    firewall-cmd --zone=public --add-rich-rule="rule family='ipv4' source address='$ip' drop" --permanent >/dev/null 2>&1
                    print_success "Firewalld: 已封禁 IP $ip"
                fi
                ;;

            iptables)
                # Iptables 逻辑 (保持原样，直接操作链头)
                iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
                iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
                iptables -I INPUT 1 -s "$ip" -j "$target"
                
                if [[ "$target" == "ACCEPT" ]]; then
                    print_success "Iptables: 已放行 IP $ip"
                else
                    print_success "Iptables: 已封禁 IP $ip"
                fi
                ;;
        esac
    done

    # 4. 持久化保存，刷新配置
    case "$backend" in
        ufw) ufw reload >/dev/null 2>&1 ;;
        firewalld) firewall-cmd --reload >/dev/null 2>&1 ;;
        iptables) _iptables_save_persistence ;;
    esac
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

    local backend
    backend=$(_get_firewall_backend)

    for ip in "${ips[@]}"; do
        case "$backend" in
            ufw)
                ufw delete allow from "$ip" >/dev/null 2>&1
                ufw delete deny from "$ip" >/dev/null 2>&1
                print_success "UFW: 已移除 IP $ip 的所有规则"
                ;;
            
            firewalld)
                firewall-cmd --zone=public --remove-rich-rule="rule family='ipv4' source address='$ip' accept" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --remove-rich-rule="rule family='ipv4' source address='$ip' drop" --permanent >/dev/null 2>&1
                print_success "Firewalld: 已移除 IP $ip 的所有规则"
                ;;
            
            iptables)
                iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
                iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
                print_success "Iptables: 已移除 IP $ip 的所有规则"
                ;;
        esac
    done

    # 持久化保存，刷新配置
    case "$backend" in
        ufw) ufw reload >/dev/null 2>&1 ;;
        firewalld) firewall-cmd --reload >/dev/null 2>&1 ;;
        iptables) _iptables_save_persistence ;;
    esac
}

# ------------------------------------------------------------------------------
# 核心逻辑: 查看 IP 规则
# ------------------------------------------------------------------------------
firewall_list_ips() {
    local backend
    backend=$(_get_firewall_backend)
    print_info "当前后端: $backend"
    print_line
    
    case "$backend" in
        ufw)
            print_echo "${BOLD_CYAN}UFW 自定义 IP 规则:${NC}"
            # 过滤出含 IP 的规则 (Anywhere 代表所有，这里只看特定 IP)
            ufw status numbered | grep -E "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
            ;;
            
        firewalld)
            print_echo "${BOLD_CYAN}Firewalld Rich Rules:${NC}"
            firewall-cmd --zone=public --list-rich-rules
            ;;
            
        iptables)
            print_echo "${BOLD_CYAN}Iptables 手动规则 (INPUT Top):${NC}"
            iptables -S INPUT | grep -E "\-s [0-9]" | grep -v "match-set" | awk '{
                if ($0 ~ /DROP/) type="\033[31m[黑名单]\033[0m"
                else if ($0 ~ /ACCEPT/) type="\033[32m[白名单]\033[0m"
                else type="[其他]"
                for(i=1;i<=NF;i++) if($i=="-s") ip=$(i+1)
                printf " %-20s %s\n", type, ip
            }'
            ;;
    esac
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
    print_echo "${RED}警告: 此操作将移除所有手动添加的 IP 白名单和黑名单规则！${NC}"
    print_echo "(注: 不会影响 15-19 号的国家级封禁规则)"
    
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