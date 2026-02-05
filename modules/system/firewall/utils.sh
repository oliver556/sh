#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 防火墙公共底层库
#
# @文件路径: modules/system/firewall/utils.sh
# @功能描述: 提供后端检测、持久化、Iptables 基础封装等通用能力
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-23
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: _get_firewall_backend
# 功能:   检测系统当前正在运行的防火墙后端
# 
# 参数:
#   无
# 
# 返回值:
#   (stdout) - "ufw" | "firewalld" | "iptables"
# 
# 示例:
#   backend=$(_get_firewall_backend)
# ------------------------------------------------------------------------------
_get_firewall_backend() {
    if command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
        echo "firewalld"
    else
        echo "iptables"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: _iptables_save_persistence
# 功能:   [内部函数] 保存 iptables 规则并设置持久化 (重启生效)
#         尝试使用 crontab @reboot 或 rc.local
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   _iptables_save_persistence
# ------------------------------------------------------------------------------
_iptables_save_persistence() {
    local save_path="/etc/iptables/rules.v4"
    mkdir -p /etc/iptables
    
    # 1. 保存当前规则
    iptables-save > "$save_path"
    print_echo "${ICON_ARROW}$(print_spaces 1)规则已保存至 $save_path"

    # 2. 最兼容的方法：Crontab (虽然土，但在极简环境下最通用)
    if command -v crontab >/dev/null 2>&1; then
        local job="@reboot /sbin/iptables-restore < $save_path"
        local current_cron
        current_cron=$(crontab -l 2>/dev/null)
        
        if [[ "$current_cron" != *"$save_path"* ]]; then
            (echo "$current_cron"; echo "$job") | crontab -
            print_echo "  -> 已添加 Crontab 启动恢复任务"
        fi
    else
        # 尝试使用 rc.local 作为备选
        if [ -f /etc/rc.local ]; then
             if ! grep -q "iptables-restore" /etc/rc.local; then
                 sed -i -e '$i \/sbin\/iptables-restore < \/etc\/iptables\/rules.v4\n' /etc/rc.local
                 chmod +x /etc/rc.local
             fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# API: 统一开放端口接口 (供 SSH、Web 等其他模块调用)
# ------------------------------------------------------------------------------
firewall_api_open_port() {
    local port="$1"
    local protocol="${2:-tcp}" # 默认 TCP，也可以传 udp 或 tcp/udp

    if [[ -z "$port" ]]; then return 1; fi

    local backend
    backend=$(_get_firewall_backend)

    case "$backend" in
        ufw)
            if [[ "$protocol" == "tcp/udp" ]]; then
                ufw allow "$port" >/dev/null 2>&1
            else
                ufw allow proto "$protocol" from any to any port "$port" >/dev/null 2>&1
            fi
            print_success "UFW: 已添加规则放行端口 ${BOLD_WHITE}${port}${NC} (${protocol})"
            ;;
            
        firewalld)
            if [[ "$protocol" == "tcp/udp" ]]; then
                firewall-cmd --zone=public --add-port="${port}/tcp" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --add-port="${port}/udp" --permanent >/dev/null 2>&1
            else
                firewall-cmd --zone=public --add-port="${port}/${protocol}" --permanent >/dev/null 2>&1
            fi
            firewall-cmd --reload >/dev/null 2>&1
            print_success "Firewalld: 已添加规则放行端口 ${BOLD_WHITE}${port}${NC} (${protocol})"
            ;;
            
        iptables)
            # 纯 IPTables 逻辑
            if [[ "$protocol" == "tcp/udp" ]] || [[ "$protocol" == "tcp" ]]; then
                if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
                    iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
                fi
            fi
            if [[ "$protocol" == "tcp/udp" ]] || [[ "$protocol" == "udp" ]]; then
                if ! iptables -C INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null; then
                    iptables -I INPUT -p udp --dport "$port" -j ACCEPT
                fi
            fi
            _iptables_save_persistence
            print_success "Iptables: 已添加临时规则放行端口 ${BOLD_WHITE}${port}${NC} (${protocol})"
            print_info "          (提示: Iptables 规则已尝试自动保存)"
            ;;
    esac
    return 0
}

# ------------------------------------------------------------------------------
# [新增] 防火墙状态仪表盘 (供菜单调用)
# ------------------------------------------------------------------------------
firewall_get_status_view() {
    local backend
    backend=$(_get_firewall_backend)
    
    local status_display=""
    local policy_display=""
    local count_display=""

    case "$backend" in
        ufw)
            # UFW 状态检测
            if systemctl is-active --quiet ufw; then
                if ufw status | grep -q "Status: active"; then
                    status_display="${GREEN}运行中 (Active)${NC}"
                    
                    # 获取默认策略
                    local incoming
                    incoming=$(ufw status verbose | grep "Default:" | grep -o "deny (incoming)" || echo "allow")
                    if [[ "$incoming" == *"deny"* ]]; then
                        policy_display="${GREEN}拒绝入站 (安全)${NC}"
                    else
                        policy_display="${RED}允许入站 (风险)${NC}"
                    fi
                else
                    status_display="${YELLOW}运行但未启用 (Inactive)${NC}"
                fi
            else
                status_display="${RED}未运行${NC}"
            fi
            ;;

        firewalld)
            if systemctl is-active --quiet firewalld; then
                status_display="${GREEN}运行中 (Active)${NC}"
                local zone
                zone=$(firewall-cmd --get-default-zone 2>/dev/null)
                policy_display="Zone: ${GREEN}${zone}${NC}"
            else
                status_display="${RED}未运行${NC}"
            fi
            ;;

        iptables)
            status_display="${GREEN}内核级接管${NC}"
            # 检测 INPUT 链默认策略
            local policy
            policy=$(iptables -L INPUT | grep "Chain INPUT" | awk '{print $4}' | tr -d ')')
            if [[ "$policy" == "DROP" ]]; then
                policy_display="${GREEN}DROP (默认拒绝)${NC}"
            else
                policy_display="${RED}ACCEPT (默认允许)${NC}"
            fi
            ;;
    esac

    # 渲染仪表盘
    print_line -c "-" -C "$BOLD_GREY"
    print_key_value -k "当前后端 (Backend)" -v "${BOLD_CYAN}${backend^^}${NC}" -w 20
    print_key_value -k "运行状态 (Status)"  -v "${status_display}" -w 20
    print_key_value -k "安全策略 (Policy)"  -v "${policy_display}" -w 20
    print_line -c "-" -C "$BOLD_GREY"
}

# ------------------------------------------------------------------------------
# 函数名: _iptables_flush_all_logic
# 功能:   [内部函数] 彻底清空 iptables 规则并将默认策略设为 ACCEPT
#         (即裸奔模式，用于解决 Oracle 等机器无法连接的问题)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   _iptables_flush_all_logic
# ------------------------------------------------------------------------------
_iptables_flush_all_logic() {
    # 1. 将默认策略设置为 ACCEPT (最重要的第一步，防止清空规则后直接断联)
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    # 2. 清空所有默认链的规则
    iptables -F
    # 3. 删除所有用户自定义链
    iptables -X
    
    # 4. 清理 NAT 表 (如果有)
    iptables -t nat -F 2>/dev/null
    iptables -t nat -X 2>/dev/null
    
    # 5. 清理 Mangle 表 (如果有)
    iptables -t mangle -F 2>/dev/null
    iptables -t mangle -X 2>/dev/null
    
    print_info "iptables 规则已清空，默认策略已设为 ACCEPT"
}
