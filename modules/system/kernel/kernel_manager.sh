#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - 内核管理逻辑库
# 功能: 提供 XanMod 内核安装、卸载、CPU检测等底层函数
# ==============================================================================

# ------------------------------------------------------------------------------
# 内部函数: 实际执行 XanMod 安装
# ------------------------------------------------------------------------------
_install_xanmod_action() {
    # 接收可选的回调函数名
    local is_auto="${1:-false}"
    local resume_callback="${1:-}"

    print_step "正在初始化安装环境..."
    local arch
    arch=$(uname -m)
    
    # ==========================
    # 分支 A: x86_64 架构 (Intel/AMD)
    # ==========================
    if [[ "$arch" == "x86_64" ]]; then
        print_info "当前架构: x86_64 (推荐使用官方 XanMod)"
        
        # 1. 安装依赖
        apt-get update -y
        apt-get install -y wget gnupg

        # 2. 添加密钥
        print_step "添加 XanMod GPG 密钥..."
        wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

        # 3. 添加仓库
        print_step "添加 apt 仓库..."
        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

        # 4. 智能检测 CPU 等级
        print_step "智能检测 CPU 指令集等级 (v1-v4)..."
        wget -q https://dl.xanmod.org/check_x86-64_psabi.sh
        chmod +x check_x86-64_psabi.sh
        
        local cpu_level
        cpu_level=$(./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
        rm -f check_x86-64_psabi.sh
        
        if [[ -z "$cpu_level" ]]; then
            cpu_level="1"
            print_warn "CPU 检测失败，将使用通用兼容版本 (v1)"
        else
            print_success "检测到高性能 CPU，匹配等级: ${CYAN}x86-64-v${cpu_level}${NC}"
        fi

        # 5. 安装
        print_step "正在安装 XanMod BBRv3 内核 (v${cpu_level})..."
        apt-get update -y
        if apt-get install -y "linux-xanmod-x64v${cpu_level}"; then
            print_success "内核安装成功！"
            if [[ -n "$resume_callback" ]]; then
                set_resume_point "$resume_callback"
                
                print_box_success -m "内核更新完成，即将自动重启"
                print_warn "系统将在重启后自动继续执行后续任务。"
                print_warn "如果当前窗口长时间未重连，请直接关闭并重新打开一个 SSH 窗口即可。"
                
                # 倒计时
                for i in {3..1}; do echo -n "$i... "; sleep 1; done
                echo
                
                # 尝试杀死所有 sshd 进程，强制客户端断开连接，不等待超时
                killall sshd 2>/dev/null
                
                # 立即重启
                reboot
                exit 0
            else
                # 如果没有回调，走原来的询问逻辑
                _prompt_reboot
            fi
        else
            print_error "安装失败，请检查网络连接。"
        fi

    # ==========================
    # 分支 B: aarch64 架构 (ARM)
    # ==========================
    elif [[ "$arch" == "aarch64" ]]; then
        print_warn "当前架构: aarch64 (Oracle ARM 专用模式)"
        print_echo "由于 Oracle ARM 引导特殊，将调用专用的适配脚本进行安装。"
        print_echo "来源: jhb.ovh/jb/bbrv3arm.sh"
        
        local confirm
        confirm=$(read_choice -s 1 -m "是否确认执行 Oracle ARM 专用安装? [y/N]")
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            print_step "正在下载并执行 ARM 适配脚本..."
            # 直接调用专用脚本
            bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
            
            # 注意：该脚本执行完通常会自动重启或退出，如果它没重启，我们提示一下
            print_success "ARM 专用脚本执行完毕。"
            _prompt_reboot
        else
            print_info "操作已取消。"
        fi

    # ==========================
    # 分支 C: 其他架构 (不支持)
    # ==========================
    else
        print_error "不支持的 CPU 架构: $arch"
    fi
}

# ------------------------------------------------------------------------------
# 内部函数: 卸载 XanMod
# ------------------------------------------------------------------------------
_remove_xanmod_action() {
    local arch
    arch=$(uname -m)

    if [[ "$arch" == "x86_64" ]]; then
        print_step "正在卸载 XanMod 内核 (x86_64)..."
        apt-get purge -y 'linux-*xanmod*'
        update-grub
        rm -f /etc/apt/sources.list.d/xanmod-release.list
        print_success "XanMod 已卸载。"
        
    elif [[ "$arch" == "aarch64" ]]; then
        print_warn "ARM 架构是通过第三方脚本安装的内核。"
        print_echo "建议使用该脚本自带的卸载功能，或手动切换回 Oracle 默认内核。"
        print_echo "是否尝试简单清理 (不保证成功)? [y/N]"
        local confirm
        read -r confirm
        if [[ "$confirm" == "y" ]]; then
             # 尝试卸载常见的自定义内核名，这步比较危险，不做深度实现
             print_info "正在尝试移除自定义内核..."
             apt-get purge -y 'linux-image-*-xanmod*' 2>/dev/null
             update-grub
             print_success "清理指令已执行。"
        fi
    fi
    
    print_info "系统将在重启后生效。"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 辅助函数: 重启提示
# ------------------------------------------------------------------------------
_prompt_reboot() {
    print_warn "注意: 必须重启 VPS，新内核才会生效。"
    local reboot_now
    reboot_now=$(read_choice -s 1 -m "是否立即重启? [y/N]")
    if [[ "$reboot_now" == "y" || "$reboot_now" == "Y" ]]; then
        reboot
    fi
}

# ------------------------------------------------------------------------------
# 导出函数: 检查内核状态并展示信息
# ------------------------------------------------------------------------------
get_kernel_info() {
    local kernel_release
    kernel_release=$(uname -r)
    
    if [[ "$kernel_release" == *"xanmod"* ]]; then
        print_echo "${GREEN}XanMod BBRv3 ($kernel_release)${NC}"
    else
        print_echo "${GRAY}系统默认 ($kernel_release)${NC}"
    fi
}

# ==============================================================================
# [新增] 智能逻辑: 一键开启 BBRv3
# ==============================================================================
enable_bbrv3_smart() {
    # 接收参数：如果是 "true" 或 "auto" 则为自动模式，否则为手动模式
    local is_auto="${1:-false}"

    print_clear
    print_box_info -s start -m "BBRv3 加速"
    local arch
    arch=$(uname -m)

    # -----------------------------------------------------------
    # 分支 A: ARM 架构 -> 全权委托给专用脚本
    # -----------------------------------------------------------
    if [[ "$arch" == "aarch64" ]]; then
        print_clear
        print_box_info -m "Oracle ARM BBR 管理器"
        print_echo "${YELLOW}提示：${NC}检测到 ARM 架构，将启动专用的第三方管理脚本。"
        print_echo "该脚本功能强大，支持安装内核、开启 BBR、切换队列算法(Cake/FQ)等。"
        print_line
        print_echo "请在接下来的菜单中根据需要选择："
        print_echo "   1. 安装内核 (安装后需重启)"
        print_echo "   3-6. 开启 BBR 及选择算法 (重启后使用)"
        print_line
        
        print_wait_enter "按回车键启动专用脚本..."
        
        # 直接调用专用脚本，不再执行后续逻辑
        bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
        return
    fi

    # -----------------------------------------------------------
    # 分支 B: x86 架构 -> 执行原本的智能逻辑
    # -----------------------------------------------------------
    print_step "正在检查系统环境 (x86_64)..."
    local current_kernel
    current_kernel=$(uname -r)

    # 1. 检查是否已经是 XanMod 内核
    if [[ "$current_kernel" == *"xanmod"* ]]; then
        print_success "检测到 XanMod 内核 ($current_kernel)，准备启用 BBRv3..."
        
        # 清理可能存在的旧配置
        if grep -q "bbr" /etc/sysctl.conf; then
            sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
        fi
        
        # 强制写入标准 BBR 开启参数
        cat >> /etc/sysctl.conf << EOF
# Added by VpsScriptKit BBRv3
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
        sysctl -p >/dev/null 2>&1
        
        print_success "BBRv3 已成功开启！"
        print_echo "   拥塞控制: ${GREEN}$(sysctl -n net.ipv4.tcp_congestion_control)${NC}"
        print_echo "   队列调度: ${GREEN}$(sysctl -n net.core.default_qdisc)${NC}"
        print_box_success -s finish -m "BBRv3 加速"
    else
        # 2. 不是 XanMod，提示安装
        print_warn "当前内核 ($current_kernel) 不支持原生 BBRv3。"

        if [[ "$is_auto" == "true" ]]; then
            # 分支 B.1: 自动模式 -> 强制安装
            print_tip "检测到一键调优模式，正在自动安装 XanMod 内核并开启..."
            # 这里的 sleep 是为了让用户看清提示，非必须
            sleep 1 
            _install_xanmod_action
        else
        # 分支 B.2: 手动模式 -> 询问用户
            local confirm
            confirm=$(read_choice -s 1 -m "是否自动安装 XanMod 内核并开启? [y/N]")
            
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                print_tip "正在自动安装 XanMod 内核并开启"
                _install_xanmod_action
            else
                print_info "操作已取消。"
                print_wait_enter
            fi
        fi
    fi
}

# ==============================================================================
# [新增] 智能逻辑: 一键关闭/还原
# ==============================================================================
disable_bbrv3_smart() {
    local arch
    arch=$(uname -m)

    # ARM 架构同样交给专用脚本去处理关闭逻辑
    if [[ "$arch" == "aarch64" ]]; then
        print_warn "ARM 架构请使用专用脚本进行管理/关闭。"
        print_wait_enter "按回车键启动专用脚本..."
        bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
        return
    fi

    # x86 架构继续执行原来的清理逻辑
    print_clear
    print_box_info -m "关闭 BBRv3 / 恢复默认"
    
    # 1. 移除 sysctl 参数
    print_step "正在移除 BBR 相关参数..."
    sed -i '/net.core.default_qdisc = fq/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control = bbr/d' /etc/sysctl.conf
    sed -i '/# Added by VpsScriptKit BBRv3/d' /etc/sysctl.conf
    
    # 2. 检查是否安装了 XanMod，询问是否卸载
    if dpkg -l | grep -q 'linux-xanmod'; then
        print_line
        print_echo "检测到系统安装了 XanMod 内核。"
        local remove_k
        remove_k=$(read_choice -s 1 -m "是否同时卸载 XanMod 内核，恢复系统默认内核? [y/N]")
        
        if [[ "$remove_k" == "y" || "$remove_k" == "Y" ]]; then
            _remove_xanmod_action
            return
        fi
    fi
    
    sysctl -p >/dev/null 2>&1
    print_success "BBR 配置已移除 (保留了当前内核)。"
}