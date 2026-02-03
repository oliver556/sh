#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - SSH 核心逻辑库
#
# @文件路径: modules/system/ssh/ssh_core.sh
# @功能描述: 提供 SSH 公钥写入、配置修改、服务重启等核心原子操作
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-02-02
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: ssh_add_key
# 功能:   将公钥字符串安全地写入 authorized_keys
# 参数:   $1 (字符串) - 公钥内容
#
# 返回:
#   0 - 新增成功
#   1 - 失败
#   2 - 已存在(跳过)
# ------------------------------------------------------------------------------
ssh_add_key() {
    local pub_key="$1"
    local ssh_dir="$HOME/.ssh"
    local auth_file="$ssh_dir/authorized_keys"

    # 1. 基础校验
    if [[ -z "$pub_key" ]]; then
        print_error -m "公钥内容为空, 跳过写入。"
        return 1
    fi

    # 2. 格式校验 (格式弱校验)
    if [[ ! "$pub_key" =~ ^ssh- ]]; then
        print_warn -m "格式警告: 非标准 ssh- 开头公钥"
    fi

    # 3. 准备目录与权限 (关键安全步骤)
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
    fi
    chmod 700 "$ssh_dir"
    touch "$auth_file"

    # 4. 幂等性检查 (防止重复添加)
    # grep -F 纯文本匹配, -x 整行匹配, -q 静默
    if grep -Fxq "$pub_key" "$auth_file" 2>/dev/null; then
        print_blank
        print_info -c "${ICON_ARROW}" -m "跳过: 公钥已存在"
        return 2
    fi

    # 5. 写入并修正权限
    echo "$pub_key" >> "$auth_file"
    chmod 600 "$auth_file"
    
    print_blank
    # 成功提示 (上层脚本可以捕获这个 0 状态码来计数)
    print_success -m "新增: 成功添加公钥"
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: ssh_check_policy_status
# 功能:   检测当前是否已经是安全模式 (禁止了密码登录)
# 返回:
#   0 - 安全(已禁密码)
#   1 - 不安全(允许密码)
# ------------------------------------------------------------------------------
ssh_check_policy_status() {
    local config="/etc/ssh/sshd_config"
    # 提取 PasswordAuthentication 的最终值
    local val
    val=$(grep -i "^[[:space:]]*PasswordAuthentication" "$config" | tail -n 1 | awk '{print $2}')
    
    # 如果值为 no，说明已经是安全模式
    if [[ "${val,,}" == "no" ]]; then
        return 0
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ssh_apply_policy
# 功能:   应用 SSH 安全策略 (禁止密码, 开启密钥)
# ------------------------------------------------------------------------------
ssh_apply_policy() {
    print_step -m "正在开启密钥模式 (禁止密码登录)..."
    
    local sshd_config="/etc/ssh/sshd_config"
    local bak_file
    bak_file="${sshd_config}.bak_$(date +%Y%m%d_%H%M%S)"

    # 1. 备份配置
    if [[ -f "$sshd_config" ]]; then
        cp "$sshd_config" "$bak_file"
    fi
    
    # 2. 修改配置 (使用 sed 批量处理)
    # PermitRootLogin: 建议改为 prohibit-password (允许Root密钥登录, 禁止Root密码登录)
    # PasswordAuthentication: no (全局禁止密码)
    # PubkeyAuthentication: yes (开启密钥)
    sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
           -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
           -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
           -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' \
           "$sshd_config"

    # 3. 清理干扰配置 (Include 目录下的配置可能会覆盖主配置)
    rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null

    # 4. 重启服务
    _restart_ssh_service

    print_box_success -s ok -m "密钥模式已开启！"
    print_info -m "策略: [密码登录: \033[31m禁止\033[0m] [密钥登录: \033[32m允许\033[0m]"

    # 5. 保命提示 (仅显示一次)
    print_blank
    print_box_warn -m "【安全警告】"
    print_warn -m "请勿关闭当前窗口！请立即新开终端测试连接。"
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: ssh_restore_policy
# 功能:   [关闭] 密钥模式 (恢复密码登录)
# ------------------------------------------------------------------------------
ssh_restore_policy() {
    print_clear

    print_box_info -m "关闭密钥模式 (恢复密码登录)"

    if ! read_confirm "确定要恢复密码登录吗? (安全性降低)"; then
        return 1
    fi

    print_step -m "正在恢复密码登录模式..."
    
    local sshd_config="/etc/ssh/sshd_config"
    local auth_file="$HOME/.ssh/authorized_keys"
    
    # 1. 备份配置
    cp "$sshd_config" "${sshd_config}.bak_restore_$(date +%Y%m%d_%H%M%S)"

    # 2. [基础恢复] 先强制开启 密码登录 和 Root 权限
    # PermitRootLogin: yes (允许Root密码登录)
    # PasswordAuthentication: yes (允许)
    sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin yes/' \
           -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
           "$sshd_config"

    # 3. [询问] 是否同时关闭密钥登录功能？(决定是否回到纯密码模式)
    if read_confirm -n -m "是否同时关闭 SSH 密钥登录功能 (PubkeyAuthentication)?"; then
        # 用户选择关闭 -> 彻底禁用密钥
        sed -i 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication no/' "$sshd_config"
        print_warn -m "SSH 密钥登录功能已禁用。"
    else
        # 用户选择保留 -> 双轨制 (推荐)
        sed -i 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' "$sshd_config"
        print_info -m "保持 SSH 密钥登录功能开启 (双轨模式)。"
    fi
    
    # 4. [清理询问] 是否清空授权列表
    # 即使关闭了密钥功能，询问是否清理旧钥匙也是合理的（为了整洁）
    print_blank
    print_box_warn -m "【权限管理】"
    print_info -m "密码登录已恢复。"
    
    if read_confirm -n -m "是否要清空已授权的公钥列表 (authorized_keys)?"; then
        cp "$auth_file" "${auth_file}.bak_$(date +%Y%m%d)"
        : > "$auth_file"
        print_success -m "已清空授权列表。"
    else
        print_info -m "保留了授权列表。"
    fi

    # 4. 重启服务
    _restart_ssh_service

    print_box_success -s ok -m "SSH 策略已更新！"
    
    # 6. 提示私钥文件的处理
    if [[ -f "$HOME/.ssh/vsk_sshkey" ]]; then
        print_blank
        print_info -I "${ICON_TIP}" -m "提示: 本机生成的私钥文件 (${BOLD_WHITE}~/.ssh/vsk_sshkey${NC}) 未被删除。"
        print_info -m "如果您确定不再需要它, 请手动删除以保持目录整洁。"
    fi

    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: ssh_get_status_view
# 功能:   获取并显示当前 SSH 配置状态 (用于菜单展示)
# ------------------------------------------------------------------------------
ssh_get_status_view() {
    local config="/etc/ssh/sshd_config"
    
    # 辅助函数：从配置文件提取参数 (忽略注释, 取最后生效的一行)
    _get_cfg() {
        grep -i "^[[:space:]]*$1" "$config" | tail -n 1 | awk '{print $2}'
    }

    local pass_auth
    pass_auth=$(_get_cfg "PasswordAuthentication")
    local pub_auth
    pub_auth=$(_get_cfg "PubkeyAuthentication")
    local root_login
    root_login=$(_get_cfg "PermitRootLogin")
    local keep_alive_interval
    keep_alive_interval=$(_get_cfg "ClientAliveInterval")

    # 默认值处理 (如果没配置, 通常 Linux 默认如下)
    pass_auth=${pass_auth:-yes}
    pub_auth=${pub_auth:-yes}
    root_login=${root_login:-yes}
    keep_alive_interval=${keep_alive_interval:-0} # 默认为 0 (关闭)

    # --- 格式化显示 ---
    
    # 1. 密钥状态
    local pub_display
    if [[ "${pub_auth,,}" == "yes" ]]; then
        pub_display="${GREEN}已启用${NC}"
    else
        pub_display="${GREY}未启用${NC}"
    fi

    # 2. 密码状态
    local pass_display
    if [[ "${pass_auth,,}" == "no" ]]; then
        pass_display="${GREEN}已禁用 (安全)${NC}"
    else
        pass_display="${RED}已启用 (风险)${NC}"
    fi
    
    # 3. Root 登录状态
    local root_display
    case "${root_login,,}" in
        yes)
            # 如果全局密码开了，Root yes 就是高风险
            # 如果全局密码关了，Root yes 其实也只能用密钥，但配置上不够严谨
            if [[ "${pass_auth,,}" == "no" ]]; then
                 root_display="${YELLOW}允许 (受限于全局)${NC}"
            else
                 root_display="${RED}允许 (密码/密钥)${NC}"
            fi
            ;;
        no)
            root_display="${GREEN}禁止登录${NC}" 
            ;;
        prohibit-password|without-password) 
            root_display="${GREEN}仅限密钥 (推荐)${NC}" 
            ;;
        forced-commands-only) 
            root_display="${YELLOW}受限命令${NC}" 
            ;;
        *)                 
            root_display="${root_login}" 
            ;;
    esac

    # 4. [新增] 端口状态
    local current_port
    current_port=$(ssh_get_port)
    local port_display
    if [[ "$current_port" == "22" ]]; then
        port_display="${YELLOW}22 (默认/高风险)${NC}"
    else
        port_display="${GREEN}${current_port} (已隐藏)${NC}"
    fi

    # 5. KeepAlive 状态
    local keep_display
    if [[ "$keep_alive_interval" -gt 0 ]]; then
        keep_display="${GREEN}已开启 (${keep_alive_interval}s)${NC}"
    else
        keep_display="${GREY}未开启${NC}"
    fi

    # 渲染状态栏
    print_line -c "-" -C "$BOLD_GREY"
    print_key_value -k "SSH  密钥登录" -v "$pub_display"
    print_key_value -k "SSH  密码登录" -v "$pass_display"
    print_key_value -k "Root 登录权限" -v "$root_display"
    print_key_value -k "当前 SSH 端口" -v "$port_display"
    print_key_value -k "防断连 (保活)" -v "$keep_display"
    print_line -c "-" -C "$BOLD_GREY"
}

# 内部函数: 重启服务
_restart_ssh_service() {
    if command -v systemctl &>/dev/null; then
        systemctl restart sshd
    elif command -v service &>/dev/null; then
        service sshd restart
    else
        /etc/init.d/ssh restart 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ssh_get_port
# 功能:   获取当前 SSH 端口 (优先读取配置，默认22)
# ------------------------------------------------------------------------------
ssh_get_port() {
    local port
    port=$(grep -E '^Port [0-9]+' /etc/ssh/sshd_config | tail -n 1 | awk '{print $2}')
    echo "${port:-22}"
}