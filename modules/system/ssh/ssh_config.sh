#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - SSH 高级配置
#
# @文件路径: modules/system/ssh/ssh_config.sh
# @功能描述: SSH 高级配置 (端口、KeepAlive、Config生成、审计)
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-02-03
# ==============================================================================

# shellcheck disable=1091
source "${BASE_DIR}/modules/system/ssh/ssh_core.sh"

# ------------------------------------------------------------------------------
# 函数名: ssh_set_port (核心功能函数 - 给自动化脚本用)
# 功能:   静默修改端口、配置防火墙、重启服务
# 参数:   $1 (port)
# ------------------------------------------------------------------------------
ssh_set_port() {
    local target_port="$1"

    # 1. 基础校验 (兼容自动化调用的参数检查)
    # 如果没传参，报错
    if [[ -z "$target_port" ]]; then
        print_error "ssh_set_port: 缺少端口参数"
        return 1
    fi

    # 正则校验
    if declare -f is_digit >/dev/null; then
        if ! is_digit "$target_port"; then print_error "端口必须是纯数字"; return 1; fi
    fi

    if [[ "$target_port" -lt 1 || "$target_port" -gt 65535 ]]; then
        print_error "端口号超出范围 (1-65535)"
        return 1
    fi

    local ssh_config="/etc/ssh/sshd_config"
    if [[ ! -f "$ssh_config" ]]; then
        print_error "找不到 $ssh_config"
        return 1
    fi

    print_step -m "正在设置 SSH 端口为: ${BOLD_WHITE}$target_port${NC}"

    # 2. 备份配置
    cp "$ssh_config" "${ssh_config}.bak_port_$(date +%Y%m%d_%H%M%S)"

    # 3. 修改配置 (Sed)
    sed -i 's/^\s*#Port\s*/Port /' "$ssh_config"
    sed -i "s/^Port .*/Port $target_port/" "$ssh_config"

    # 4. 自动配置防火墙 (静默模式)
    local fw_done=false
    
    # TODO: [重构预留] 
    # UFW
    if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
        ufw allow "$target_port"/tcp >/dev/null 2>&1
        fw_done=true
    fi
    # Firewalld
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        firewall-cmd --permanent --add-port="$target_port"/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
        fw_done=true
    fi
    # Iptables
    if command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "$target_port" -j ACCEPT 2>/dev/null
        fw_done=true
    fi

    if [[ "$fw_done" == "true" ]]; then
        print_info -m "已自动放行本地防火墙端口。"
    else
        print_warn -m "未检测到活动防火墙或配置失败，请手动检查。"
    fi

    # 5. 重启服务
    _restart_ssh_service
    
    # 6. 验证
    sleep 1
    if netstat -tnlp 2>/dev/null | grep -q ":$target_port "; then
         print_success -m "SSH 端口已修改为: ${BOLD_GREEN}$target_port${NC}"
         return 0
    else
         # 兜底提示
         print_success -m "SSH 服务已重启 (端口: $target_port)。"
         return 0
    fi
}

# ------------------------------------------------------------------------------
# 1. 修改 SSH 端口
# ------------------------------------------------------------------------------
ssh_change_port() {
    print_clear
    print_box_info -m "修改 SSH 端口"

    # 获取当前端口
    local current_port
    current_port=$(ssh_get_port)
    print_info -m "当前 SSH 端口: ${BOLD_YELLOW}${current_port}${NC}"
    
    print_box_info -s start -m "配置向导"
    print_info -m "推荐端口范围: 1024 - 65535（输入 0 退出）"

    local target_port
    target_port=$(read_choice -s 1 -m "请输入新的 SSH 端口")

    # 基础校验
    if ! is_digit "$target_port"; then
        print_error -m "输入无效，请输入数字"
        sleep 2
        return 1
    fi

    if [[ "$target_port" -eq 0 ]]; then
        return 0
    fi

    if [[ "$target_port" -lt 1 || "$target_port" -gt 65535 ]]; then
        print_error "端口号超出范围 (1-65535)"
        return 1
    fi

    if [[ "$target_port" == "$current_port" ]]; then
        print_warn "端口未改变。"
        return 1
    fi

    print_step -m "正在修改端口配置..."

    # 核心修改逻辑 (Sed 替换)
    local ssh_config="/etc/ssh/sshd_config"
    if [[ ! -f "$ssh_config" ]]; then
        print_error "找不到 $ssh_config"
        return 1
    fi

    # 备份是个好习惯
    cp "$ssh_config" "${ssh_config}.bak_port_$(date +%Y%m%d)"

    # 确保能匹配到 Port
    sed -i 's/^\s*#Port\s*/Port /' "$ssh_config"
    # 执行替换
    sed -i "s/^Port .*/Port $target_port/" "$ssh_config"

    # ============================================================
    # 尝试放行防火墙
    # TODO: [重构预留] 未来此处应调用高级防火墙模块的统一接口 
    # 例如: firewall_manager_allow "$target_port" "tcp"
    print_step -m "正在配置防火墙..."
    local fw_done=false
    
    # UFW 支持
    if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
        ufw allow "$target_port"/tcp
        print_info -m "已添加 UFW 规则: allow $target_port/tcp"
        fw_done=true
    fi
    # Firewalld 支持 (CentOS/Fedora)
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        firewall-cmd --permanent --add-port="$target_port"/tcp
        firewall-cmd --reload
        print_info -m "已添加 Firewalld 规则: $target_port/tcp"
        fw_done=true
    fi
    # Iptables 支持
    if command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "$target_port" -j ACCEPT 2>/dev/null
        print_info -m "已添加 Iptables 临时规则 (重启可能失效)"
        fw_done=true
    fi

    if [[ "$fw_done" == "false" ]]; then
        print_warn -m "未检测到活动防火墙或无法自动配置，请手动放行端口 $target_port"
    fi

    # ============================================================

    # [重要提示] 云厂商防火墙
    print_blank
    print_box_warn -m "【重要提示】"
    print_warn -m "如果使用的是阿里云、腾讯云、AWS、GCP 等云服务器"
    print_warn -m "请务必去【云控制台 - 安全组】放行 TCP 端口: ${BOLD_GREEN}$target_port${NC}"
    
    if ! read_confirm -n -m "确认已放行防火墙/安全组?"; then
        print_warn "已取消重启服务，配置已修改但未生效。"
        return 1
    fi

    # 重启服务 (调用 ssh_core 中的通用重启函数)
    _restart_ssh_service
    
    # 验证是否重启成功 (简单的端口监听检查)
    sleep 1
    if netstat -tnlp 2>/dev/null | grep -q ":$target_port "; then
         print_success -m "SSH 端口已修改为: ${BOLD_GREEN}$target_port${NC}"
    else
         # 如果 netstat 不存在或者查不到，只要服务没报错也算成功，给个提示
         print_success -m "SSH 服务已重启。下次请使用端口 $target_port 登录。"
    fi
}

# ------------------------------------------------------------------------------
# 2. 开启 KeepAlive (防断连)
# ------------------------------------------------------------------------------
ssh_enable_keepalive() {
    print_clear
    print_box_info -m "SSH 连接防断开配置"

    local config="/etc/ssh/sshd_config"

    # 1. 获取当前状态
    # 提取 ClientAliveInterval 的值
    local current_interval
    current_interval=$(grep -i "^[[:space:]]*ClientAliveInterval" "$config" | tail -n 1 | awk '{print $2}')
    current_interval=${current_interval:-0}

    # 2. 显示当前状态
    if [[ "$current_interval" -gt 0 ]]; then
        print_info -m "当前状态: ${GREEN}已开启${NC} (心跳间隔: ${current_interval}秒)"
    else
        print_info -m "当前状态: ${YELLOW}未开启${NC}"
    fi

    print_blank
    print_info -m "说明: 开启后服务器每 60 秒发送一次心跳，允许失败 3 次。"
    print_info -m "      这可以有效防止 SSH 客户端因长时间空闲而断开连接。"
    
    # 3. 智能交互: 开启或关闭
    if [[ "$current_interval" -gt 0 ]]; then
        # 如果已开启，询问是否关闭
        if read_confirm -m "检测到已开启，是否关闭防断开功能?"; then
            # 移除配置
            sed -i '/ClientAliveInterval/d' "$config"
            sed -i '/ClientAliveCountMax/d' "$config"
            
            _restart_ssh_service
            print_success -m "已关闭防断连配置。"
            print_wait_enter
        fi
    else
        # 如果未开启，询问是否开启
        if read_confirm -m "是否开启防断开功能 (ClientAliveInterval 60)?"; then
            cp "$config" "${config}.bak_keepalive"
            
            # 清理旧配置并追加新配置
            sed -i '/ClientAliveInterval/d' "$config"
            sed -i '/ClientAliveCountMax/d' "$config"
            
            echo "ClientAliveInterval 60" >> "$config"
            echo "ClientAliveCountMax 3" >> "$config"
            
            _restart_ssh_service
            print_success -m "已开启防断连配置 (需重连生效)。"
            print_wait_enter
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. 生成本地 Config (贴心功能)
# ------------------------------------------------------------------------------
ssh_generate_local_config() {
    print_clear
    print_box_info -m "生成本地连接配置"
    
    # 自动获取信息
    local ip
    if declare -f net_get_ipv4 > /dev/null; then ip=$(net_get_ipv4); else ip="<服务器IP>"; fi
    local port
    port=$(ssh_get_port)
    
    print_echo -n "${BOLD_CYAN}设置别名 (如 hk, rn) (回车默认 myserver): ${NC}"
    local alias_name
    read -r alias_name
    alias_name=${alias_name:-myserver}

    # 使用单引号包裹默认值，防止在服务器端被解析为 /root/...
    # 我们希望默认值就是字符串 "~/.ssh/vsk_sshkey"
    print_echo -n "${BOLD_CYAN}私钥路径 (回车默认 ~/.ssh/vsk_sshkey): ${NC}"
    local key_path
    read -r key_path

    # 如果用户没输入，强制赋值为波浪号字符串
    if [[ -z "$key_path" ]]; then
        key_path="~/.ssh/vsk_sshkey"
    fi

    print_blank
    print_line -c "-"
    echo "${GREEN}Host ${alias_name}${NC}"
    echo "    HostName ${ip}"
    echo "    User root"
    echo "    Port ${port}"
    echo "    IdentityFile ${key_path}"
    echo "    ServerAliveInterval 60"
    print_line -c "-"
    print_blank
    
    print_box_warn -m "【重要】配置步骤:"
    print_info -m "1. 在本机(Mac/PC)执行权限修复 (防止Permission denied):"
    # 动态生成修复命令
    print_warn "   chmod 600 ${key_path}"
    print_info -m "2. 复制上方内容追加到本机文件: ${BOLD_WHITE}~/.ssh/config${NC}"
    print_info -m "3. 连接命令: ${BOLD_GREEN}ssh ${alias_name}${NC}"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 4. 日志审计
# ------------------------------------------------------------------------------
ssh_audit_logs() {
    print_clear
    print_box_info -m "SSH 登录日志审计"
    
    print_box_header_tip -h "最近成功的登录"
    last -n 5 -a | head -n 5
    
    print_blank
    print_box_header_tip -h "最近失败的尝试 (Bad Login)"
    if [ -r /var/log/btmp ]; then
        lastb -n 5 -a 2>/dev/null | head -n 5 || echo "无记录或工具缺失"
    else
        print_warn "无法读取失败日志 (/var/log/btmp)"
    fi
    
    print_wait_enter
}