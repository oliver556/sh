#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 高级防火墙管理 - 工具
#
# @文件路径: modules/system/firewall/utils.sh
# @功能描述: 高级防火墙管理核心逻辑与工具函数库
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-23
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: firewall_start_open_port
# 功能:   启动开放端口的 UI 交互流程
#         提示用户输入端口号，解析输入，并调用核心逻辑函数
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功或用户取消
# 
# 示例:
#   firewall_start_open_port
# ------------------------------------------------------------------------------
firewall_start_open_port() {
    print_clear
    print_box_info -s start -m "开放指定端口"
    print_echo "端口号范围: 1 到 65535 之间的数字（输入 0 退出）"

    # 1. 获取输入
    local input_ports
    input_ports=$(read_choice -s 1 -m "请输入要开放的端口号 (空格分隔，如: 80 443)")

    # 2. 判断取消
    # 这里用 == "0" 比较字符串，防止输入 "80 443" 时 -eq 报错
    if [[ "$input_ports" == "0" ]] || [[ -z "$input_ports" ]]; then
        print_info -m "操作已取消"
        return 0
    fi

    # 3. 转换数组
    local port_array
    read -r -a port_array <<< "$input_ports"

    # 4. 调用核心逻辑
    run_step -S 2 -m "正在配置防火墙规则..." firewall_open_port "${port_array[@]}"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_close_port
# 功能:   启动关闭端口的 UI 交互流程
#         提示用户输入端口号，解析输入，并调用核心逻辑函数
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功或用户取消
# 
# 示例:
#   firewall_start_close_port
# ------------------------------------------------------------------------------
firewall_start_close_port() {
    print_clear
    print_box_info -s start -m "关闭指定端口"
    print_echo "警告：关闭 SSH 端口可能导致无法连接服务器，请谨慎操作。"
    
    # 1. 获取输入
    local input_ports
    input_ports=$(read_choice -s 1 -m "请输入要关闭的端口号 (空格分隔，如: 80 443)")

    # 2. 判断取消
    if [[ "$input_ports" == "0" ]] || [[ -z "$input_ports" ]]; then
        print_info -m "操作已取消"
        return 0
    fi

    # 3. 转换数组
    local port_array
    read -r -a port_array <<< "$input_ports"

    # 4. 调用核心逻辑
    # 传递 -S 2 让进度条样式统一
    run_step -S 2 -m "正在移除防火墙规则..." firewall_close_port "${port_array[@]}"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_open_all
# 功能:   启动开放所有端口（裸奔模式）的 UI 交互流程
#         包含高风险操作的二次确认
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功或用户取消
# 
# 示例:
#   firewall_start_open_all
# ------------------------------------------------------------------------------
firewall_start_open_all() {
    print_clear
    print_box_info -s start -m "开放所有端口 (裸奔模式)"
    
    # 警告信息
    print_echo "${RED}警告：此操作将执行以下动作，服务器安全性将大幅降低！${NC}"
    print_echo "  1. 停止并禁用 UFW / Firewalld 服务"
    print_echo "  2. 清空所有 iptables 规则 (包括 NAT/Mangle)"
    print_echo "  3. 允许所有进出流量"
    print_blank

    # 1. 获取确认输入
    local confirm
    confirm=$(read_choice -s 1 -m "请输入 [yes] 确认执行 (其他任意内容取消)")

    # 2. 判断输入
    if [[ "$confirm" != "yes" ]]; then
        print_info -m "操作已取消"
        sleep 1
        return 0
    fi

    # 3. 执行逻辑
    run_step -S 2 -m "正在移除所有防火墙限制..." firewall_open_all
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_list
# 功能:   启动查看端口列表的 UI 交互流程
#         调用 firewall_list_ports 并显示辅助说明信息
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   firewall_start_list
# ------------------------------------------------------------------------------
firewall_start_list() {
    print_clear
    print_box_info -m "当前防火墙规则预览"
    
    firewall_list_ports
    
    print_blank
    print_line
    print_echo "说明:"
    print_echo "1. PROTO: 协议 (tcp/udp)"
    print_echo "2. RELATED/EST: 已建立的连接 (保持不断线)"
    print_echo "3. 0.0.0.0/0: 代表允许所有来源 IP"
}

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
# 函数名: _iptables_open_logic
# 功能:   [内部函数] 针对 iptables 后端执行开放端口操作 (仅当无 UFW/Firewalld 时调用)
# 
# 参数:
#   $1 (String/Int): 端口号 (必填)
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   _iptables_open_logic "8080"
# ------------------------------------------------------------------------------
_iptables_open_logic() {
    local port="$1"

    # 1. 如果之前有 DROP 规则，先清理掉 (防止冲突)
    iptables -D INPUT -p tcp --dport "$port" -j DROP 2>/dev/null
    iptables -D INPUT -p udp --dport "$port" -j DROP 2>/dev/null

    # 2. 检查是否已经存在 ACCEPT 规则 (幂等性检查)，不存在才添加
    # 备注：使用 -A (Append) 而不是 -I (Insert) 1，避免破坏 Chain 头部逻辑
    # 如果为了保险起见一定要插在前面，可以用 -I INPUT 1，但要小心
    
    if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
        iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
        print_echo "  -> iptables: TCP $port 规则已添加"
    fi

    if ! iptables -C INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null; then
        iptables -I INPUT -p udp --dport "$port" -j ACCEPT
        print_echo "  -> iptables: UDP $port 规则已添加"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: _iptables_close_logic
# 功能:   [内部函数] 针对 iptables 后端执行关闭端口操作
# 
# 参数:
#   $1 (String/Int): 端口号 (必填)
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   _iptables_close_logic "8080"
# ------------------------------------------------------------------------------
_iptables_close_logic() {
    local port="$1"

    # 尝试删除 TCP 的 ACCEPT 规则
    # 2>/dev/null 是为了防止规则不存在时报错
    if iptables -D INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
         print_echo "  -> iptables: TCP $port 允许规则已移除"
    fi

    # 尝试删除 UDP 的 ACCEPT 规则
    if iptables -D INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null; then
         print_echo "  -> iptables: UDP $port 允许规则已移除"
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
    print_echo "  -> 规则已保存至 $save_path"

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
# 函数名: firewall_open_port
# 功能:   开放一个或多个端口，自动适配当前防火墙后端 (UFW/Firewalld/Iptables)
# 
# 参数:
#   $@ (Array): 端口号列表 (如: "80" "443" "8000:9000")
# 
# 返回值:
#   0 - 成功
#   1 - 未指定端口
# 
# 示例:
#   firewall_open_port "80" "443"
# ------------------------------------------------------------------------------
firewall_open_port() {
    local ports=("$@") # 将传入的参数转换为数组

    if [ ${#ports[@]} -eq 0 ]; then
        print_error "未指定任何端口"
        return 1
    fi
    
    local backend
    backend=$(_get_firewall_backend)
    print_step "检测到防火墙后端: [${backend}]，正在处理..."

    for port in "${ports[@]}"; do
        # 简单校验一下是不是数字（防止注入）
        if ! [[ "$port" =~ ^[0-9]+(:[0-9]+)?$ ]]; then
            print_warn "忽略非法端口格式: $port"
            continue
        fi

        case "$backend" in
            ufw)
                # UFW 同时开放 TCP 和 UDP
                # 如果包含冒号(范围)，通常需要明确协议，否则 UFW 可能会报错
                if [[ "$port" == *":"* ]]; then
                    ufw allow proto tcp from any to any port "$port" >/dev/null 2>&1
                    ufw allow proto udp from any to any port "$port" >/dev/null 2>&1
                else
                    ufw allow "$port" >/dev/null 2>&1
                fi
                print_success "UFW: 已开放端口 $port (TCP/UDP)"
                ;;
                
            firewalld)
                # Firewalld 需要分别加 tcp/udp，并且要 --permanent
                firewall-cmd --zone=public --add-port="${port}/tcp" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --add-port="${port}/udp" --permanent >/dev/null 2>&1
                print_success "Firewalld: 已开放端口 $port (TCP/UDP)"
                ;;
                
            iptables)
                # 纯 Iptables 逻辑 (优化版)
                _iptables_open_logic "$port"
                ;;
        esac
    done

    # 重载规则
    case "$backend" in
        ufw) ufw reload >/dev/null 2>&1 ;;
        firewalld) firewall-cmd --reload >/dev/null 2>&1 ;;
        iptables) _iptables_save_persistence ;; # 只有纯 iptables 需要手动持久化
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_close_port
# 功能:   关闭一个或多个端口，自动适配当前防火墙后端
# 
# 参数:
#   $@ (Array): 端口号列表 (如: "80" "443")
# 
# 返回值:
#   0 - 成功
#   1 - 未指定端口
# 
# 示例:
#   firewall_close_port "80" "443"
# ------------------------------------------------------------------------------
firewall_close_port() {
    local ports=("$@")

    if [ ${#ports[@]} -eq 0 ]; then
        print_error "未指定任何端口"
        return 1
    fi

    local backend
    backend=$(_get_firewall_backend)
    print_step "检测到防火墙后端: [${backend}]，正在处理..."

    for port in "${ports[@]}"; do
        # 简单校验
        if ! [[ "$port" =~ ^[0-9]+(:[0-9]+)?$ ]]; then
            print_warn "忽略非法端口格式: $port"
            continue
        fi

        case "$backend" in
            ufw)
                # UFW 删除规则
                # 使用 delete allow 对应之前的 allow
                # 如果包含冒号(范围)，通常需要明确协议，否则 UFW 可能会报错
                if [[ "$port" == *":"* ]]; then
                    ufw delete allow proto tcp from any to any port "$port" >/dev/null 2>&1
                    ufw delete allow proto udp from any to any port "$port" >/dev/null 2>&1
                else
                    ufw delete allow "$port" >/dev/null 2>&1
                fi
                print_success "UFW: 已移除端口 $port 规则"
                ;;
                
            firewalld)
                # Firewalld 移除规则
                firewall-cmd --zone=public --remove-port="${port}/tcp" --permanent >/dev/null 2>&1
                firewall-cmd --zone=public --remove-port="${port}/udp" --permanent >/dev/null 2>&1
                print_success "Firewalld: 已移除端口 $port 规则"
                ;;
                
            iptables)
                # 纯 Iptables 逻辑
                _iptables_close_logic "$port"
                ;;
        esac
    done

    # 重载规则以生效
    case "$backend" in
        ufw) ufw reload >/dev/null 2>&1 ;;
        firewalld) firewall-cmd --reload >/dev/null 2>&1 ;;
        iptables) _iptables_save_persistence ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_open_all
# 功能:   开放所有端口（裸奔模式）
#         停用 UFW/Firewalld，清空 Iptables 并允许所有流量
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_open_all
# ------------------------------------------------------------------------------
firewall_open_all() {
    # 1. 停止并禁用 UFW (如果存在)
    if command -v ufw >/dev/null 2>&1; then
        if systemctl is-active --quiet ufw; then
            ufw disable >/dev/null 2>&1
            print_success "UFW: 服务已停止并禁用"
        fi
    fi

    # 2. 停止并禁用 Firewalld (如果存在)
    if command -v firewall-cmd >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld; then
            systemctl stop firewalld >/dev/null 2>&1
            systemctl disable firewalld >/dev/null 2>&1
            print_success "Firewalld: 服务已停止并禁用"
        fi
    fi

    # 3. 无论上面是谁，底层 iptables 都要彻底洗白 (针对 Oracle 等商家预设规则)
    _iptables_flush_all_logic

    # 4. 持久化 (保存这个“全开”的状态，防止重启后商家预设规则恢复)
    _iptables_save_persistence
    
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: firewall_reset
# 功能:   重置防火墙到安全状态
#         1. 默认策略 DROP
#         2. 放行 SSH (自动检测端口，兜底 22)
#         3. 放行 HTTP/HTTPS/Ping/Loopback
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_reset
# ------------------------------------------------------------------------------
firewall_reset() {
    # 1. 获取 SSH 端口 (优先尝试 ss，失败则尝试 netstat，最后兜底 22)
    local ssh_port
    if command -v ss >/dev/null 2>&1; then
        ssh_port=$(ss -tlnp | grep sshd | awk '{print $4}' | awk -F: '{print $NF}' | head -n 1)
    elif command -v netstat >/dev/null 2>&1; then
        ssh_port=$(netstat -ntlp 2>/dev/null | awk '/sshd/ {split($4,a,":"); print a[NF]}' | head -n 1)
    fi
    
    # 如果以上都失败，使用默认 22
    if [[ -z "$ssh_port" || ! "$ssh_port" =~ ^[0-9]+$ ]]; then ssh_port=22; fi

    local backend
    backend=$(_get_firewall_backend)

    case "$backend" in
        ufw)
            # UFW 重置逻辑
            ufw --force reset >/dev/null 2>&1
            ufw default deny incoming >/dev/null 2>&1
            ufw default allow outgoing >/dev/null 2>&1
            ufw allow "$ssh_port"/tcp >/dev/null 2>&1
            ufw allow 80/tcp >/dev/null 2>&1
            ufw allow 443/tcp >/dev/null 2>&1
            ufw --force enable >/dev/null 2>&1
            print_success "UFW: 已重置规则并放行 SSH($ssh_port)"
            ;;

        firewalld)
            # Firewalld 重置逻辑
            # 重新加载默认配置
            rm -f /etc/firewalld/zones/public.xml
            systemctl restart firewalld
            
            # 确保放行 SSH
            firewall-cmd --zone=public --add-port="$ssh_port"/tcp --permanent >/dev/null 2>&1
            firewall-cmd --zone=public --add-service=http --permanent >/dev/null 2>&1
            firewall-cmd --zone=public --add-service=https --permanent >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            print_success "Firewalld: 已重置规则并放行 SSH($ssh_port)"
            ;;

        iptables)
            # 1. 先清空
            iptables -P INPUT ACCEPT
            iptables -F
            iptables -X
            
            # 2. 允许环回接口
            iptables -A INPUT -i lo -j ACCEPT
            # 3. 允许已建立的连接 (这一步非常重要，防止打断当前连接)
            iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
            # 4. 允许 SSH
            iptables -A INPUT -p tcp --dport "$ssh_port" -j ACCEPT
            # 5. 允许 HTTP/HTTPS
            iptables -A INPUT -p tcp --dport 80 -j ACCEPT
            iptables -A INPUT -p tcp --dport 443 -j ACCEPT
            # 6. 允许 Ping
            iptables -A INPUT -p icmp -j ACCEPT
            
            # 7. 最后设置默认拒绝
            iptables -P INPUT DROP
            iptables -P FORWARD DROP
            
            # 8. 持久化
            _iptables_save_persistence
            print_success "Iptables: 已重置规则并放行 SSH($ssh_port)"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_reset
# 功能:   启动重置防火墙的 UI 交互流程
#         包含操作说明和二次确认
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功或用户取消
# 
# 示例:
#   firewall_start_reset
# ------------------------------------------------------------------------------
firewall_start_reset() {
    print_clear
    print_box_info -m "重置防火墙规则"
    print_echo "此操作将执行以下重置："
    print_echo "  1. 默认策略设为拒绝 (DROP)"
    print_echo "  2. 放行 SSH 端口 (防止失联)"
    print_echo "  3. 放行 HTTP/HTTPS (80/443)"
    print_echo "  4. 放行 ICMP (Ping) 和 本地回环"
    print_blank

    local confirm
    confirm=$(read_choice -s 1 -m "请输入 [yes] 确认重置")

    if [[ "$confirm" != "yes" ]]; then
        print_info -m "操作已取消"
        return 0
    fi
    
    run_step -S 2 -m "正在重置防火墙安全策略..." firewall_reset
}

# ------------------------------------------------------------------------------
# 函数名: firewall_list_ports
# 功能:   查看并美化显示当前防火墙规则
#         支持 UFW/Firewalld/Iptables，智能解析端口范围、协议和 IP
# 
# 参数:
#   无
# 
# 返回值:
#   无 (直接输出到 stdout)
# 
# 示例:
#   firewall_list_ports
# ------------------------------------------------------------------------------
firewall_list_ports() {
    local backend
    backend=$(_get_firewall_backend)
    
    print_info "当前防火墙后端: [${backend}]"

    case "$backend" in
        ufw)
            if ! systemctl is-active --quiet ufw; then
                print_warn "UFW 服务未运行"
            else
                print_echo "${BOLD_GREEN}UFW 规则列表:${NC}"
                ufw status numbered
            fi
            ;;

        firewalld)
            if ! systemctl is-active --quiet firewalld; then
                print_warn "Firewalld 服务未运行"
            else
                print_echo "${BOLD_GREEN}Firewalld (Public Zone):${NC}"
                local ports services
                ports=$(firewall-cmd --zone=public --list-ports)
                services=$(firewall-cmd --zone=public --list-services)
                
                print_echo "  - 开放端口: ${ports:-"无"}"
                print_echo "  - 开放服务: ${services:-"无"}"
                print_echo "  - 允许来源: Anywhere (默认)"
            fi
            ;;

        iptables)
            # --- 1. 获取默认策略 ---
            local in_policy out_policy
            in_policy=$(iptables -L INPUT | grep "Chain INPUT" | awk '{print $4}' | sed 's/)//')
            out_policy=$(iptables -L OUTPUT | grep "Chain OUTPUT" | awk '{print $4}' | sed 's/)//')
            
            print_line
            if [[ "$in_policy" == "ACCEPT" ]]; then
                print_echo "  • 入站总控 (INPUT) : ${RED}ACCEPT (允许所有/裸奔)${NC}"
            else
                print_echo "  • 入站总控 (INPUT) : ${GREEN}DROP (默认拒绝/安全)${NC}"
            fi
            
            if [[ "$out_policy" == "ACCEPT" ]]; then
                print_echo "  • 出站总控 (OUTPUT): ${GREEN}ACCEPT (不限制对外访问)${NC}"
            else
                print_echo "  • 出站总控 (OUTPUT): ${RED}DROP (限制对外访问)${NC}"
            fi
            print_line

            print_echo "${BOLD_CYAN}  [入站规则详情]${NC}"
            
            # --- 2. 打印表头 (关键修改：SOURCE列给22宽，补偿中文宽度差) ---
            printf "  %-4s %-6s %-15s %-22s %-s\n" "ID" "PROTO" "PORT" "SOURCE (来源)" "DEST (目标/本机)"
            print_echo "  -------------------------------------------------------------------------"
            
            # --- 3. 获取并解析规则内容 ---
            local rules_content
            rules_content=$(iptables -L INPUT -n --line-numbers | grep "^[[:space:]]*[0-9]" | grep "ACCEPT" | awk '{
                id=$1
                proto=$3
                source=$5
                dest=$6
                port="-"

                # 协议转换
                if(proto=="6") proto="tcp"
                else if(proto=="17") proto="udp"
                else if(proto=="1") proto="icmp"
                else if(proto=="0") proto="all"

                # IP 转换
                if(source=="0.0.0.0/0") source="Anywhere"
                if(dest=="0.0.0.0/0") dest="Anywhere"

                # 提取端口 (支持 dpt: 和 dpts:)
                for(i=7;i<=NF;i++) {
                    if($i ~ /dpt:/ || $i ~ /dpts:/) { 
                        port=$i; 
                        gsub("dpts?:", "", port); 
                    }
                    else if($i ~ /state/) { 
                        port="RELATED/EST"; 
                    }
                }
                
                # 兜底显示
                if(port=="-") {
                    if (proto == "all") port="ALL PORTS"
                    else port="Any " proto
                }

                # 数据行 SOURCE 列保持 20 宽
                printf "  %-4s %-6s %-15s %-20s %-s\n", id, proto, port, source, dest
            }')

            # --- 4. 智能显示逻辑 ---
            if [[ -n "$rules_content" ]]; then
                echo "$rules_content"
            else
                if [[ "$in_policy" == "ACCEPT" ]]; then
                    # 虚拟行：数据列 SOURCE 保持 20 宽
                    printf "  %-4s %-6s ${GREEN}%-15s${NC} %-20s %-s\n" "-" "all" "ALL PORTS" "Anywhere" "Anywhere (默认策略)"
                else
                    print_echo "  (当前无明确允许规则，且默认策略为拒绝，所有入站被阻断)"
                fi
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_enable_ping
# 功能:   允许 ICMP (Ping) 流量
#         适配 UFW (删除拒绝规则), Firewalld (移除阻塞), Iptables (添加允许规则)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_enable_ping
# ------------------------------------------------------------------------------
firewall_enable_ping() {
    local backend
    backend=$(_get_firewall_backend)
    
    case "$backend" in
        ufw)
            # UFW 默认允许 Ping (在 before.rules 中)，这里主要是为了移除用户可能设置过的 deny 规则
            # 尝试移除 "deny proto icmp" 规则
            ufw delete deny proto icmp from any to any >/dev/null 2>&1
            # 也可以尝试移除针对 input 的 icmp 拒绝
            ufw delete deny in proto icmp >/dev/null 2>&1
            print_success "UFW: 已移除 ICMP 拒绝规则 (允许 Ping)"
            ;;
            
        firewalld)
            # 移除 echo-request 的阻塞
            firewall-cmd --zone=public --remove-icmp-block=echo-request --permanent >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            print_success "Firewalld: 已移除 ICMP 阻塞 (允许 Ping)"
            ;;
            
        iptables)
            # 1. 先清理旧的关于 ICMP 的 DROP 规则 (防止冲突)
            iptables -D INPUT -p icmp --icmp-type 8 -j DROP 2>/dev/null
            
            # 2. 检查是否已有 ACCEPT，没有则添加
            if ! iptables -C INPUT -p icmp --icmp-type 8 -j ACCEPT 2>/dev/null; then
                iptables -I INPUT -p icmp --icmp-type 8 -j ACCEPT
            fi
            
            # 持久化
            _iptables_save_persistence
            print_success "Iptables: 已添加 ICMP 允许规则"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_disable_ping
# 功能:   禁止 ICMP (Ping) 流量
#         适配 UFW (添加拒绝规则), Firewalld (添加阻塞), Iptables (添加丢弃规则)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_disable_ping
# ------------------------------------------------------------------------------
firewall_disable_ping() {
    local backend
    backend=$(_get_firewall_backend)

    case "$backend" in
        ufw)
            # 添加拒绝规则 (插入到最前，优先级最高)
            ufw insert 1 deny proto icmp from any to any >/dev/null 2>&1
            print_success "UFW: 已添加 ICMP 拒绝规则 (禁止 Ping)"
            ;;
            
        firewalld)
            # 添加 echo-request 的阻塞
            firewall-cmd --zone=public --add-icmp-block=echo-request --permanent >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            print_success "Firewalld: 已添加 ICMP 阻塞 (禁止 Ping)"
            ;;
            
        iptables)
            # 1. 先清理旧的 ACCEPT 规则
            iptables -D INPUT -p icmp --icmp-type 8 -j ACCEPT 2>/dev/null
            
            # 2. 添加 DROP 规则 (插入到最前)
            if ! iptables -C INPUT -p icmp --icmp-type 8 -j DROP 2>/dev/null; then
                iptables -I INPUT -p icmp --icmp-type 8 -j DROP
            fi
            
            # 持久化
            _iptables_save_persistence
            print_success "Iptables: 已添加 ICMP 丢弃规则"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_enable_ping
# 功能:   启动允许 Ping 的流程 (UI 交互 wrapper)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_start_enable_ping
# ------------------------------------------------------------------------------
firewall_start_enable_ping() {
    print_clear
    print_box_info -m "允许 Ping (ICMP)"
    
    # 直接执行，无需太多确认，因为是安全操作
    run_step -S 2 -m "正在移除 ICMP 限制..." firewall_enable_ping
    
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_disable_ping
# 功能:   启动禁止 Ping 的流程 (UI 交互 wrapper)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_start_disable_ping
# ------------------------------------------------------------------------------
firewall_start_disable_ping() {
    print_clear
    print_box_info -m "禁止 Ping (ICMP)"
    print_echo "${YELLOW}提示: 禁止 Ping 可以让服务器隐身，但也会导致无法使用 Ping 工具检测服务器在线状态。${NC}"
    print_blank

    local confirm
    confirm=$(read_choice -s 1 -m "是否确认禁止 Ping? [yes/no]")

    if [[ "$confirm" != "yes" ]]; then
        print_info -m "操作已取消"
        return 0
    fi

    run_step -S 2 -m "正在配置 ICMP 拒绝规则..." firewall_disable_ping
    
    print_wait_enter
}