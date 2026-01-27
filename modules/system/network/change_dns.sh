#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 修改 DNS
#
# @文件路径: modules/system/network/change_dns.sh
# @功能描述: 修改 DNS 地址
#
# @作者: Jamison
# @版本: 1.0.1
# @创建日期: 2026-01-20
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: do_check_general_connectivity
# 功能:   静默测试一般网络连通性 (Ping google.com)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 连通
#   1 - 不通
# ------------------------------------------------------------------------------
do_check_general_connectivity() {
    timeout 5 ping -c 1 google.com >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 函数名: do_check_dns_server
# 功能:   静默测试指定 IP 的 DNS 解析能力
# 
# 参数:
#   $1 (字符串): DNS 服务器 IP 地址 (如 8.8.8.8)
# 
# 返回值:
#   0 - 解析成功
#   1 - 解析失败
# ------------------------------------------------------------------------------
do_check_dns_server() {
    local dns_ip=$1
    
    case $DNS_TOOL in
        "nslookup")
            timeout 5 nslookup google.com "$dns_ip" >/dev/null 2>&1
            ;;
        "dig")
            timeout 5 dig @"$dns_ip" google.com +short >/dev/null 2>&1
            ;;
        "host")
            timeout 5 host google.com "$dns_ip" >/dev/null 2>&1
            ;;
        "ping")
            timeout 3 ping -c 1 "$dns_ip" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: test_dns_server
# 功能:   (旧版/备用) 显式测试 DNS 并打印结果
#         注意: 该函数包含 echo 输出，不适用于 run_step
# 
# 参数:
#   $1 (字符串): DNS IP
#   $2 (字符串): DNS 名称描述
# 
# 返回值:
#   无 (直接输出结果到屏幕)
# ------------------------------------------------------------------------------
test_dns_server() {
    local dns_ip=$1
    local dns_name=$2
    
    echo -ne "${BLUE}[${ICON_TEST}]${NC} 测试 $dns_name ($dns_ip)... "
    
    case $DNS_TOOL in
        "nslookup")
            if timeout 5 nslookup google.com $dns_ip &> /dev/null; then
                echo -e "${GREEN}${ICON_OK} 正常${NC}"
            else
                echo -e "${RED}${ERROR} 失败${NC}"
            fi
            ;;
        "dig")
            if timeout 5 dig @$dns_ip google.com +short &> /dev/null; then
                echo -e "${GREEN}${ICON_OK} 正常${NC}"
            else
                echo -e "${RED}${ERROR} 失败${NC}"
            fi
            ;;
        "host")
            if timeout 5 host google.com $dns_ip &> /dev/null; then
                echo -e "${GREEN}${ICON_OK} 正常${NC}"
            else
                echo -e "${RED}${ERROR} 失败${NC}"
            fi
            ;;
        "ping")
            if timeout 3 ping -c 1 $dns_ip &> /dev/null; then
                echo -e "${GREEN}${ICON_OK} 可达${NC}"
            else
                echo -e "${RED}${ERROR} 不可达${NC}"
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 函数名: do_write_dns_global
# 功能:   写入国际通用 DNS 配置 (Google + Cloudflare)
#         包含 IPv4 和 IPv6 以及优化参数
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 写入成功
#   1 - 写入失败
# ------------------------------------------------------------------------------
do_write_dns_global() {
    tee /etc/resolv.conf > /dev/null <<EOF
# =================================================================
# 🚀 优化 DNS 配置 - (国际模式)
# 生成时间: $(date)
# =================================================================

# 1. Google Public DNS (主)
nameserver 8.8.8.8

# 2. Cloudflare DNS (备 - 异构容灾)
nameserver 1.1.1.1

# 3. Google IPv6 (保留一个 IPv6 解析能力)
nameserver 2001:4860:4860::8888

# 优化选项
# timeout:1 - 1秒连不上就换下一个(默认5秒太慢)
# rotate    - 轮询使用上面的DNS实现负载均衡(可选)
options timeout:1
options attempts:2
options rotate
options single-request-reopen
EOF
}

# ------------------------------------------------------------------------------
# 函数名: do_write_dns_cn
# 功能:   写入国内优化 DNS 配置 (阿里云 + 腾讯云)
#         包含 IPv4 和 IPv6 以及优化参数
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 写入成功
#   1 - 写入失败
# ------------------------------------------------------------------------------
do_write_dns_cn() {
    tee /etc/resolv.conf > /dev/null <<EOF
# =================================================================
# 🚀 优化 DNS 配置 - (国内模式)
# 生成时间: $(date)
# =================================================================

# 1. AliDNS (阿里云 - 主)
nameserver 223.5.5.5

# 2. DNSPod (腾讯云 - 备)
nameserver 119.29.29.29

# 3. AliDNS IPv6
nameserver 2400:3200::1

# 优化选项
options timeout:1
options attempts:2
options rotate
EOF
}

# ------------------------------------------------------------------------------
# 函数名: restart_net
# 功能:   尝试重启系统网络服务 (适配 systemd)
# 
# 参数:
#   无
# 
# 返回值:
#   根据 systemctl 执行结果返回状态码
# ------------------------------------------------------------------------------
restart_net() {
    if command -v systemctl &>/dev/null; then
        systemctl restart networking 2>/dev/null || \
        systemctl restart NetworkManager 2>/dev/null || \
        systemctl restart network 2>/dev/null
    fi
    sleep 1
}

# ------------------------------------------------------------------------------
# 函数名: wait_for_net
# 功能:   循环检测网络是否恢复，用于重启网络后的阻塞等待
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 网络已恢复
#   1 - 超时 (15秒)
# ------------------------------------------------------------------------------
wait_for_net() {
    for _ in {1..15}; do
        if ping -c 1 -W 1 223.5.5.5 >/dev/null 2>&1; then return 0; fi
        sleep 1
    done
    return 1
}

# ------------------------------------------------------------------------------
# 函数名: manual_edit_dns
# 功能:   调用系统编辑器手动修改 /etc/resolv.conf
#         会自动处理文件解锁和重新加锁
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 执行完成
# ------------------------------------------------------------------------------
manual_edit_dns() {
    local editor="vi"
    if command -v nano &>/dev/null; then editor="nano"; fi
    
    # 编辑前先解锁
    chattr -i /etc/resolv.conf 2>/dev/null || true
    
    # 调用编辑器
    $editor /etc/resolv.conf
    
    # 编辑后询问是否锁定
    print_blank
    
    local choice_lock
    # 使用 $() 捕获 read_input 的输出
    choice_lock=$(read_input -s 1 -m "是否锁定文件防止被覆盖? [y/n]" -d "y")
    
    if [[ "$choice_lock" == "y" ]]; then
        chattr +i /etc/resolv.conf
        print_success "文件已锁定"
    else
        print_warn "文件未锁定，重启后可能被覆盖"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: modify_dns_task
# 功能:   执行自动修改 DNS 的完整流程 (备份->写入->重启->测试)
# 
# 参数:
#   -d | --dist (字符串): 配置类型，可选 "global"(默认) 或 "cn"
# 
# 返回值:
#   0 - 流程结束
#   1 - 参数错误
# ------------------------------------------------------------------------------
modify_dns_task() {
    local target_type="global"  # 默认值
    
    # 1. 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dist)
                target_type="$2"
                shift 2
                ;;
            *)
                shift 1
                ;;
        esac
    done

    # 2. 根据参数决定要调用的函数名
    local write_func=""
    local title_msg=""

    case "$target_type" in
        "global")
            write_func="do_write_dns_global"
            title_msg="配置新的 DNS (国际互联)"
            ;;
        "cn")
            write_func="do_write_dns_cn"
            title_msg="配置新的 DNS (国内优化)"
            ;;
        *)
            print_error "未知的 DNS 类型: $target_type"
            return 1
            ;;
    esac

    print_box_info -s start -m "DNS 优化流程"

    # --- 步骤 1: 备份文件 ---
    local backup_file
    backup_file="/etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 执行备份
    run_step -m "备份原始 DNS 配置" cp /etc/resolv.conf "$backup_file"

    # --- 步骤 2: 写入新配置 (动态调用函数)  ---
    # 先解锁 -> 再写入 -> 再锁定。尝试解锁 (如果是不可变文件)
    run_step -m "解除文件锁定" -s "完成" -- chattr -i /etc/resolv.conf 2>/dev/null || true

    # 3. 调用上面定义的函数，带转圈动画
    run_step -m "$title_msg" -s "写入成功" -- "$write_func"

    # --- 步骤 3: 锁定文件 ---
    run_step -m "保护 DNS 配置 (锁定)" chattr +i /etc/resolv.conf

    # --- 步骤 4: 重启网络 ---
    run_step -m "刷新网络状态" restart_net

    # --- 步骤 5: 等待网络恢复 ---
    run_step -m "等待网络连接恢复" -s "恢复" -e "超时" -- wait_for_net

    # --- 步骤 6: 测试 ---
    print_blank
    
    print_step "正在进行 DNS 连通性测试..."

    # 确定测试工具
    if command -v nslookup &> /dev/null; then
        DNS_TOOL="nslookup"
    elif command -v dig &> /dev/null; then
        DNS_TOOL="dig"
    elif command -v host &> /dev/null; then
        DNS_TOOL="host"
    else
        DNS_TOOL="ping"
    fi

    print_info "使用测试工具: ${CYAN}$DNS_TOOL${NC}"
    print_echo

    # 针对国内/国外做不同的重点测试 (可选优化)
    if [[ "$target_type" == "global" ]]; then
        run_step -m "测试 Google DNS" -s "正常" -e "失败" -- do_check_dns_server "8.8.8.8"
        run_step -m "测试 Cloudflare" -s "正常" -e "失败" -- do_check_dns_server "1.1.1.1"
    else
        run_step -m "测试 AliDNS" -s "正常" -e "失败" -- do_check_dns_server "223.5.5.5"
        run_step -m "测试 DNSPod" -s "正常" -e "失败" -- do_check_dns_server "119.29.29.29"
    fi

    # 通用测试
    run_step -m "测试域名解析 (google.com)" -s "正常" -e "失败" -- do_check_general_connectivity

    print_blank
    print_box_success -s finish "DNS 优化流程，已备份至: $backup_file"
}

# ------------------------------------------------------------------------------
# 函数名: guard_change_dns
# 功能:   修改 SSH 端口前的前置检查 (权限检查)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 允许进入
#   1 - 权限不足
# ------------------------------------------------------------------------------
guard_change_dns() {
    print_clear
    
    if ! check_root; then
        return 1
    fi

    change_dns
}

# ------------------------------------------------------------------------------
# 函数名: show_current_dns
# 功能:   读取并显示当前系统生效的 Nameserver
# 
# 参数:
#   无
# 
# 返回值:
#   无
# ------------------------------------------------------------------------------
show_current_dns() {
    print_echo "${BOLD_BLUE}当前 DNS 配置: ${NC}"

    if [ -f /etc/resolv.conf ]; then
        while IFS= read -r line; do
            if [[ $line == nameserver* ]]; then
                dns_ip=$(echo $line | awk '{print $2}')
                print_info "${WHITE}$line${NC}"
            fi
        done < /etc/resolv.conf
    fi
}

# ------------------------------------------------------------------------------
# 函数名: change_dns
# 功能:   DNS 修改功能的主菜单入口
#         提供国外、国内、手动编辑三种模式选择
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 正常退出
# ------------------------------------------------------------------------------
change_dns() {
    while true; do
        print_clear
    
        print_box_info -m "优化 DNS 地址"

        show_current_dns

        print_line
        print_menu_item -p 0 -i 1 -s 2 -m "国外 DNS (Google + Cloudflare)"
        print_echo "$(print_spaces 4)v4: 8.8.8.8 / 1.1.1.1"
        print_echo "$(print_spaces 4)v6: 2001:4860:4860::8888"
        print_menu_item_done -n

        print_line
        print_menu_item -p 0 -i 2 -s 2 -m "国内 DNS (阿里 + 腾讯)"
        print_echo "$(print_spaces 4)v4: 223.5.5.5 / 119.29.29.29"
        print_echo "$(print_spaces 4)v6: 2400:3200::1"
        print_menu_item_done -n

        print_line
        print_menu_item -p 0 -i 3 -s 2 -m "手动编辑"
        print_menu_item_done -n

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1)
                print_clear
                modify_dns_task -d "global"
                print_wait_enter
                ;;
            2)  
                print_clear
                modify_dns_task -d "cn"
                print_wait_enter
                ;;
            3)
                print_clear
                manual_edit_dns
                print_wait_enter
                ;;
            0)
                return
                ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
                ;;
        esac
    done
}
