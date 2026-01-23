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
