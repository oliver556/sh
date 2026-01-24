#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 国家 IP 限制管理
#
# @文件路径: modules/system/firewall/geoip.sh
# @功能描述: 基于 IPSet 的国家级黑/白名单拦截、规则查看
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-23
# ==============================================================================

# 引入依赖
# shellcheck disable=SC1091
source "${BASE_DIR}/lib/package.sh"
source "${BASE_DIR}/modules/system/memory/swap.sh"
source "${BASE_DIR}/modules/system/firewall/utils.sh"


# ------------------------------------------------------------------------------
# 函数名: firewall_block_countries
# 功能:   阻止指定国家 IP (黑名单模式)
#         使用 ipset 高效封禁，自动下载 ipdeny.com 数据
# 
# 参数:
#   $@ (Array): 国家代码列表 (如: cn us jp)
# 
# 返回值:
#   0 - 成功
#   1 - 失败
# 
# 示例:
#   firewall_block_countries "cn" "ru"
# ------------------------------------------------------------------------------
firewall_block_countries() {
    local countries=("$@")
    
    # 1. 自动依赖安装
    pkg_install "ipset" "wget" "curl" || return 1

    # 2. 【智能内存保护】检测物理内存，不足则自动创建 Swap
    # 读取 MemTotal (KB)
    local mem_total_kb
    mem_total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    
    # 阈值：1GB (1048576 KB)
    if [[ "$mem_total_kb" -lt 1048576 ]]; then
        local swap_total_kb
        swap_total_kb=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
        
        # 如果 Swap 小于 512MB，认为不足，自动扩容
        if [[ "$swap_total_kb" -lt 524288 ]]; then
            print_warn "检测到系统物理内存 < 1GB 且 Swap 不足，为防止系统卡死，正在自动创建 1GB Swap..."
            
            # 调用 swap.sh 中的函数 (需确保已 source)
            if command -v swap_create >/dev/null 2>&1; then
                # 静默创建，避免过多 UI 干扰
                swap_create 1024
            else
                print_error "无法自动创建 Swap (找不到 swap_create 函数)，建议手动增加 Swap 后再试。"
                # 内存太小且没 swap，这里强制中止比较安全
                return 1
            fi
        fi
    fi

    if [ ${#countries[@]} -eq 0 ]; then
        print_error "未指定国家代码"
        return 1
    fi

    # 3. 【核心优化】确保 "已建立连接" 规则永远在第一位！
    print_step "正在优化防火墙规则顺序..."
    iptables -D INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
    iptables -I INPUT 1 -m state --state ESTABLISHED,RELATED -j ACCEPT

    # 4. 循环处理国家
    for country in "${countries[@]}"; do
        local country_lower="${country,,}"
        local set_name="block_${country_lower}"
        local temp_file="/tmp/${country_lower}.cidr"
        
        local url="https://raw.githubusercontent.com/herrbischoff/country-ip-blocks/master/ipv4/${country_lower}.cidr"

        print_step "正在处理国家: [${country^^}]"

        if ! curl -f -L --retry 3 --connect-timeout 10 "$url" -o "$temp_file"; then
            print_error "下载失败: 无法连接 GitHub 源，请检查网络。"
            continue
        fi

        if [ ! -s "$temp_file" ]; then
            print_error "下载数据为空，跳过。"
            rm -f "$temp_file"
            continue
        fi

        if ! ipset create "$set_name" hash:net maxelem 200000 2>/dev/null; then
            if ! ipset list -n | grep -q "$set_name"; then
                print_error "创建 ipset 集合失败！可能 VPS 内核不支持。"
                rm -f "$temp_file"
                return 1
            fi
        fi
        ipset flush "$set_name"

        print_step "正在导入 IP 段 (可能耗时较长)..."
        local import_err="/tmp/ipset_import.err"
        if ! sed "s/^/add $set_name /" "$temp_file" | ipset restore 2> "$import_err"; then
             print_error "导入 IP 失败，详细信息："
             cat "$import_err"
             rm -f "$temp_file" "$import_err"
             continue
        fi
        rm -f "$temp_file" "$import_err"

        # 插入到第 2 行 (即 ESTABLISHED 之后)
        if ! iptables -C INPUT -m set --match-set "$set_name" src -j DROP 2>/dev/null; then
            iptables -I INPUT 2 -m set --match-set "$set_name" src -j DROP
            print_success "已添加拦截规则: ${country^^} (Priority: 2)"
        else
            print_info "规则已存在: ${country^^}"
        fi
    done

    _iptables_save_persistence
    print_success "所有操作已完成，连接状态保持良好。"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_block_country
# 功能:   启动阻止国家 IP 的 UI 交互流程
# 
# 参数:
#   无
# 
# 返回值:
#   无
# ------------------------------------------------------------------------------
firewall_start_block_country() {
    print_clear
    print_box_info -m "阻止指定国家 IP (黑名单)"
    print_echo "请输入国家代码 (ISO 3166-1 alpha-2)，不区分大小写。"
    print_echo "多个国家请用空格分隔，例如: CN RU JP（输入 0 退出）"
    
    local input
    input=$(read_choice -s 1 -m "请输入国家代码")
    
    if [[ -z "$input" || "$input" == "0" ]]; then 
        print_info -m "操作已取消"
        return 0;
    fi

    local countries
    read -r -a countries <<< "$input"
    
    print_line
    firewall_block_countries "${countries[@]}"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_allow_countries_only
# 功能:   仅允许指定国家 IP (白名单模式 - 高风险)
#         除了指定的国家和 SSH/Localhost 外，拒绝一切连接
# 
# 参数:
#   $@ (Array): 国家代码列表
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_allow_countries_only "cn"
# ------------------------------------------------------------------------------
firewall_allow_countries_only() {
    local countries=("$@")
    
    pkg_install "ipset" "wget" "curl" || return 1

    if [ ${#countries[@]} -eq 0 ]; then
        print_error "未指定国家代码"
        return 1
    fi

    print_warn "警告：即将启用严格白名单！除 [${countries[*]}] 及特权 IP 外，所有连接将被丢弃。"

    # --- 1. 准备特权 IP 列表 ---
    local trusted_ips=()
    
    # 自动获取当前 IP
    local current_ip=""
    
    # [修复点] 使用 ${VAR:-} 写法，防止 set -u 报错
    if [[ -n "${SSH_CLIENT:-}" ]]; then
        current_ip=$(echo "${SSH_CLIENT:-}" | awk '{print $1}')
    elif [[ -n "${SSH_CONNECTION:-}" ]]; then
        current_ip=$(echo "${SSH_CONNECTION:-}" | awk '{print $1}')
    fi
    
    # 兜底：如果环境变量都没抓到，尝试用 who -m
    if [[ -z "$current_ip" ]]; then
        current_ip=$(who -m 2>/dev/null | awk -F'[()]' '{print $2}')
    fi

    if [[ -n "$current_ip" ]]; then
        print_info "已自动识别当前管理 IP: ${BOLD_GREEN}${current_ip}${NC}"
        trusted_ips+=("$current_ip")
    fi

    # 手动补充 IP
    print_blank
    print_echo "${ICON_ARROW} 请输入额外需要放行的 IP (如您的 VPN/代理 IP):"
    print_echo "   (多个 IP 用空格分隔，若无需添加直接回车)"
    
    local manual_ips
    manual_ips=$(read_choice -s 1 -m "特权 IP 列表")
    
    if [[ -n "$manual_ips" ]]; then
        for ip in $manual_ips; do
            trusted_ips+=("$ip")
        done
    fi

    # --- 2. 准备 IPSet ---
    local set_name="allow_countries"
    if ! ipset create "$set_name" hash:net maxelem 200000 2>/dev/null; then
         # 如果已存在但类型不对，可能报错，这里简单处理
         if ! ipset list -n | grep -q "$set_name"; then
            print_error "ipset 创建失败，无法继续。"
            return 1
         fi
    fi
    ipset flush "$set_name"

    for country in "${countries[@]}"; do
        local country_lower="${country,,}"
        local url="https://raw.githubusercontent.com/herrbischoff/country-ip-blocks/master/ipv4/${country_lower}.cidr"
        local temp_file="/tmp/${country_lower}.cidr"
        
        print_step "正在下载 IP 库: [${country^^}]"
        if curl -f -L --retry 3 --connect-timeout 10 "$url" -o "$temp_file"; then
            if [ ! -s "$temp_file" ]; then
                print_error "下载数据为空，跳过"
                rm -f "$temp_file"
                continue
            fi
            sed "s/^/add $set_name /" "$temp_file" | ipset restore
            rm -f "$temp_file"
        else
            print_error "下载失败: ${country} (中止)"
            return 1
        fi
    done

    # 检查集合是否有效
    local entry_count
    entry_count=$(ipset list "$set_name" | grep "Number of entries" | awk -F: '{print $2}')
    if [[ "$entry_count" -eq 0 ]]; then
        print_error "白名单集合为空，停止操作以防锁死。"
        return 1
    fi

    # --- 3. 构建专属卫士链 (COUNTRY_GUARD) ---
    print_step "正在构建防火墙专属通道..."

    # 新建或清空自定义链
    iptables -N COUNTRY_GUARD 2>/dev/null
    iptables -F COUNTRY_GUARD

    # (1) 特权 IP -> 直接通过 (RETURN)
    for ip in "${trusted_ips[@]}"; do
        iptables -A COUNTRY_GUARD -s "$ip" -j RETURN
        print_step "添加特权规则: $ip"
    done

    # (2) 国家白名单 -> 直接通过 (RETURN)
    iptables -A COUNTRY_GUARD -m set --match-set "$set_name" src -j RETURN

    # (3) 其他杂鱼 -> 直接丢弃 (DROP)
    iptables -A COUNTRY_GUARD -j DROP

    # --- 4. 接入 INPUT 主链 ---
    
    # 临时允许所有，防止操作中掉线
    iptables -P INPUT ACCEPT
    
    # 清理旧的规则 (清理掉之前所有尝试留下的痕迹)
    # 删除跳转到 COUNTRY_GUARD 的旧规则
    iptables -D INPUT -j COUNTRY_GUARD 2>/dev/null
    # 删除旧的 ipset 拦截规则
    iptables -S INPUT | grep "$set_name" | sed 's/-A/-D/' | while read -r rule; do iptables $rule 2>/dev/null; done
    # 删除旧的 SSH 放行规则 (稍后重加)
    local ssh_port=22
    if command -v ss >/dev/null 2>&1; then
        ssh_port=$(ss -tlnp | grep sshd | awk '{print $4}' | awk -F: '{print $NF}' | head -n 1)
    fi
    iptables -D INPUT -p tcp --dport "$ssh_port" -j ACCEPT 2>/dev/null

    # 重新插入规则 (顺序必须严格)
    
    # [1] Loopback
    iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
    iptables -I INPUT 1 -i lo -j ACCEPT
    
    # [2] Established (保活)
    iptables -D INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null
    iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT

    # [3] 进入专属卫士链检查 (Check!)
    # 所有新连接必须先过这一关，过了(RETURN)才能往下走，不过的直接在链里 DROP 掉了
    iptables -I INPUT 3 -j COUNTRY_GUARD

    # [4] SSH 放行
    # 能走到这一步的，说明或者是特权IP，或者是白名单国家IP
    iptables -I INPUT 4 -p tcp --dport "$ssh_port" -j ACCEPT

    _iptables_save_persistence
    print_success "白名单严格模式已生效！"
    print_info "逻辑已更新：流量 -> COUNTRY_GUARD 链 (特权IP? 国家白名单? 否则DROP) -> 允许 SSH"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_allow_country
# 功能:   启动仅允许国家 IP 的 UI 交互流程
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_start_allow_country
# ------------------------------------------------------------------------------
firewall_start_allow_country() {
    print_clear
    print_box_info -m "仅允许指定国家 IP (白名单)"
    print_echo "${RED}危险警告：此操作将屏蔽除指定国家外的全世界所有 IP！${NC}"
    print_echo "一旦生效，非白名单 IP 将无法建立任何新连接 (包括 SSH)（输入 0 退出）"
    print_blank
    
    local input
    input=$(read_choice -s 1 -m "请输入允许的国家代码 (如: CN)")
    
    if [[ -z "$input" || "$input" == "0" ]]; then
        print_info -m "操作已取消"
        return 0;
    fi

    local countries
    read -r -a countries <<< "$input"
    
    print_line  
    firewall_allow_countries_only "${countries[@]}"
}


# ------------------------------------------------------------------------------
# 函数名: firewall_unblock_specific_country
# 功能:   解除指定国家的 IP 封禁 (针对黑名单模式)
#         移除对应的 iptables 规则并销毁 ipset 集合
# 
# 参数:
#   $@ (Array): 国家代码列表 (如: cn us)
# 
# 返回值:
#   0 - 成功
#   1 - 失败
# 
# 示例:
#   firewall_unblock_specific_country "cn"
# ------------------------------------------------------------------------------
firewall_unblock_specific_country() {
    local countries=("$@")

    if ! command -v ipset >/dev/null 2>&1; then
        print_error "未找到 ipset 命令"
        return 1
    fi

    if [ ${#countries[@]} -eq 0 ]; then
        print_error "未指定国家代码"
        return 1
    fi

    for country in "${countries[@]}"; do
        local country_lower="${country,,}"
        local set_name="block_${country_lower}"

        print_step "正在解除国家限制: [${country^^}]"

        if ! ipset list -n | grep -q "^${set_name}$"; then
            print_warn "未找到国家 [${country^^}] 的封禁记录"
            continue
        fi

        # 先删规则
        if iptables -C INPUT -m set --match-set "$set_name" src -j DROP 2>/dev/null; then
            iptables -D INPUT -m set --match-set "$set_name" src -j DROP
            print_info "已移除防火墙规则"
        fi

        # 再销毁集合
        if ipset destroy "$set_name" 2>/dev/null; then
            print_success "已销毁 IP 集合: $set_name"
        else
            ipset flush "$set_name" 2>/dev/null
            ipset destroy "$set_name" 2>/dev/null && print_success "  -> 已销毁 IP 集合" || print_error "  -> 集合销毁失败"
        fi
    done

    _iptables_save_persistence
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_unblock_specific_country
# 功能:   启动解除指定国家限制的 UI 交互流程
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_start_unblock_specific_country
# ------------------------------------------------------------------------------
firewall_start_unblock_specific_country() {
    print_clear
    print_box_info -m "解除指定国家限制 (黑名单)"
    print_echo "请输入要解封的国家代码 (如 CN US)，多个代码用空格分隔（输入 0 退出）"
    
    local input
    input=$(read_choice -s 1 -m "请输入国家代码")
    
    if [[ -z "$input" || "$input" == "0" ]]; then
        print_info -m "操作已取消"
        return 0;
    fi
    local countries
    read -r -a countries <<< "$input"
    
    print_line
    firewall_unblock_specific_country "${countries[@]}"
}


# ------------------------------------------------------------------------------
# 函数名: firewall_unblock_countries
# 功能:   解除所有国家相关的 IP 限制 (清理 ipset 和规则)
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_unblock_countries
# ------------------------------------------------------------------------------
firewall_unblock_countries() {
    print_step "正在清理国家 IP 限制规则..."

    if ! command -v ipset >/dev/null 2>&1; then
        print_error "未找到 ipset 命令，无需清理"
        return 0
    fi

    # 1. 先从 INPUT 链中断开 COUNTRY_GUARD 的连接
    iptables -D INPUT -j COUNTRY_GUARD 2>/dev/null
    
    # 2. [关键修复] 清空并删除 COUNTRY_GUARD 链
    # 必须先 Flush (-F) 清空规则，才能释放对 ipset 的占用
    if iptables -L COUNTRY_GUARD -n >/dev/null 2>&1; then
        print_step "正在拆除 COUNTRY_GUARD 专属通道..."
        iptables -F COUNTRY_GUARD
        iptables -X COUNTRY_GUARD
    fi

    # 3. 清理旧的直接引用 (兼容黑名单模式的 block_ 规则)
    iptables -S INPUT | grep "match-set block_" | sed 's/-A/-D/' | while read -r rule; do
        iptables $rule 2>/dev/null
    done
    
    # 4. 清理旧版白名单的直接引用 (如果有残留)
    iptables -D INPUT -m set ! --match-set "allow_countries" src -j DROP 2>/dev/null

    # 5. 现在可以安全销毁集合了
    # 此时没有任何规则引用它们，destroy 应该会成功
    ipset list -n | grep "block_" | xargs -r -n 1 ipset destroy 2>/dev/null
    ipset list -n | grep "allow_countries" | xargs -r -n 1 ipset destroy 2>/dev/null

    _iptables_save_persistence
    print_success "已清除所有基于国家的限制规则 (含白名单/黑名单)。"
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_unblock_country
# 功能:   启动解除国家限制的 UI 交互流程
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 成功
# 
# 示例:
#   firewall_start_unblock_country
# ------------------------------------------------------------------------------
firewall_start_unblock_country() {
    print_clear
    print_box_info -m "解除所有国家限制"
    
    local confirm
    confirm=$(read_choice -s 1 -m "确定要清除所有国家相关的黑/白名单规则吗? [yes/no]")
    
    if [[ "$confirm" != "yes" ]]; then
        print_info -m "操作已取消"
        return 0;
    fi
    
    print_line
    firewall_unblock_countries
}


# ------------------------------------------------------------------------------
# 函数名: firewall_list_country_rules
# 功能:   列出当前基于国家的 IP 限制规则 (黑/白名单状态)
# ------------------------------------------------------------------------------
firewall_list_country_rules() {
    # 依赖检查
    if ! command -v ipset >/dev/null 2>&1; then
        print_warn "未检测到 ipset 命令，无法查看国家限制规则。"
        return
    fi

    print_info "正在扫描 IPSET 集合与 IPTABLES 规则..."
    print_line

    # 1. 扫描黑名单集合 (以 block_ 开头)
    local block_sets
    block_sets=$(ipset list -n | grep "^block_")
    
    # 2. 扫描白名单集合 (固定名称 allow_countries)
    local allow_set
    allow_set=$(ipset list -n | grep "^allow_countries$")

    local found_any=0

    # --- 部分 A: 黑名单展示 ---
    if [[ -n "$block_sets" ]]; then
        print_echo "${BOLD_RED}【 黑名单 (Blacklist) - 拒绝以下国家 】${NC}"
        
        # [关键修复] 表头格式化
        # CODE: 4字节 -> %-8s (占8格)
        # IP段数量: 11字节(中文) -> %-15s (打印后视觉宽度约12格)
        # 防火墙状态: 15字节(中文) -> %-20s (打印后视觉宽度约15格)
        printf "  %-8s %-15s %-20s %-s\n" "CODE" "IP段数量" "防火墙状态" "集合名称"
        print_echo "  ----------------------------------------------------------------"
        
        for set_name in $block_sets; do
            # 提取国家代码 (去掉 block_ 前缀并转大写)
            local code="${set_name#block_}"
            code="${code^^}"
            
            # 获取该集合内的 IP 段数量
            local count
            count=$(ipset list "$set_name" | grep "Number of entries" | awk -F: '{print $2}' | tr -d ' ')
            
            # 检查 iptables 中是否有对应的 DROP 规则
            local status="${RED}未生效${NC}"
            if iptables -C INPUT -m set --match-set "$set_name" src -j DROP 2>/dev/null; then
                status="${GREEN}生效中${NC}"
            elif iptables -C COUNTRY_GUARD -m set --match-set "$set_name" src -j DROP 2>/dev/null; then
                # 兼容 COUNTRY_GUARD 链
                status="${GREEN}生效中${NC}"
            else
                status="${YELLOW}无引用${NC}"
            fi
            
            # [关键修复] 数据行格式化
            # count: ASCII数字 -> %-12s (视觉宽度12，与表头对齐)
            # status: 含颜色代码(约11字节) + 中文(9字节) -> %-29s (视觉宽度约15，与表头对齐)
            printf "  %-8s %-12s %-29s %-s\n" "$code" "$count" "$status" "$set_name"
        done
        found_any=1
        print_blank
    fi

    # --- 部分 B: 白名单展示 ---
    if [[ -n "$allow_set" ]]; then
        print_echo "${BOLD_GREEN}【 白名单 (Whitelist) - 仅允许指定国家 】${NC}"
        
        # 获取白名单 IP 总数
        local count
        count=$(ipset list allow_countries | grep "Number of entries" | awk -F: '{print $2}' | tr -d ' ')
        
        # 检查规则状态
        local status="${RED}未生效${NC}"
        # 检查 INPUT 链或 COUNTRY_GUARD 链
        if iptables -C INPUT -m set ! --match-set allow_countries src -j DROP 2>/dev/null; then
            status="${GREEN}生效中${NC}"
        elif iptables -C COUNTRY_GUARD -m set --match-set allow_countries src -j RETURN 2>/dev/null; then
            status="${GREEN}生效中${NC}"
        fi

        print_echo "  状态: $status"
        print_echo "  包含 IP 段总数: $count"
        print_echo "  ${YELLOW}说明: 白名单模式下，所有允许的国家 IP 已合并至同一个集合，无法单独显示国家列表。${NC}"
        found_any=1
        print_blank
    fi

    # --- 兜底 ---
    if [[ "$found_any" -eq 0 ]]; then
        print_info "当前没有配置任何基于国家的 IP 限制规则。"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: firewall_start_list_country_rules
# 功能:   启动查看国家限制的 UI 交互流程
# ------------------------------------------------------------------------------
firewall_start_list_country_rules() {
    print_clear
    print_box_info -m "当前国家 IP 限制预览"
    
    firewall_list_country_rules
}