#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - TCP 网络调优
#
# @文件路径: modules/system/tcp/tcp_tuning.sh
# @功能描述: 提供系统内核参数调优、BBR开启、配置备份与恢复
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-26
# ==============================================================================

# 定义常量
SYSCTL_CUSTOM_FILE="/etc/sysctl.d/99-vpsscriptkit-tuning.conf"
BACKUP_DIR="/root/vpsscriptkit_backups/sysctl"

# ------------------------------------------------------------------------------
# 内部工具: 检查内核 BBR 支持情况
# ------------------------------------------------------------------------------
_check_kernel_support_bbr() {
    # 检查内核版本是否 >= 4.9
    local kernel_version
    kernel_version=$(uname -r | cut -d. -f1,2) # 获取 5.15 这种格式
    local major
    major=$(echo "$kernel_version" | cut -d. -f1)
    local minor
    minor=$(echo "$kernel_version" | cut -d. -f2)

    if (( major < 4 )) || (( major == 4 && minor < 9 )); then
        return 1 # 不支持
    else
        return 0 # 支持
    fi
}

# ------------------------------------------------------------------------------
# 内部工具: 执行备份 (支持自定义标签)
# ------------------------------------------------------------------------------
_perform_backup() {
    local tag="$1" # 标签: manual 或 auto
    mkdir -p "$BACKUP_DIR"
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="sysctl_${tag}_${timestamp}.conf"
    local target="$BACKUP_DIR/$filename"
    
    # 备份当前生效的所有 sysctl 参数
    sysctl -a > "$target" 2>/dev/null
    
    if [[ -f "$target" ]]; then
        if [[ "$tag" == "manual" ]]; then
             print_success "备份已创建: ${filename}"
        else
             # 自动备份静默执行，或者只打印一行小字
             print_echo "${GRAY}   [系统] 已自动创建配置备份: ${filename}${NC}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 逻辑 1: 应用高性能配置 (含自动备份 & BBR 检查)
# ------------------------------------------------------------------------------
apply_performance_tuning() {
    print_clear
    print_box_info -m "应用 TCP 高性能调优配置"
    
    # --- 步骤 1: 强制自动备份 ---
    print_step "正在执行安全备份..."
    _perform_backup "auto"
    
    # --- 步骤 2: BBR 支持检查 ---
    local enable_bbr=true
    if ! _check_kernel_support_bbr; then
        print_warn "当前内核版本较低 (< 4.9)，不支持开启 BBR。"
        print_echo "脚本将仅应用 TCP 缓冲区优化，跳过 BBR 设置。"
        enable_bbr=false
        sleep 2
    fi

    print_step "正在写入优化配置文件..."
    
    # 开始构建文件内容
    cat > "$SYSCTL_CUSTOM_FILE" << EOF
# ============================================================
# VpsScriptKit TCP Tuning (Generated at $(date))
# ============================================================

# --- 系统稳定性 ---
kernel.pid_max = 65535
# OOM 时优先杀进程而非重启系统
vm.panic_on_oom = 0
vm.swappiness = 10
# 预留 128MB 内存，保证 SSH 和关键服务存活
vm.min_free_kbytes = 131072

# --- TCP 缓冲区 (必须与 Oracle 对齐) ---
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_window_scaling = 1

# --- 低延迟核心参数 ---
net.ipv4.tcp_notsent_lowat = 16384

# --- 转发与并发性能 ---
net.ipv4.ip_forward = 1
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 16384
net.ipv4.tcp_max_syn_backlog = 8192

# --- 连接回收机制 ---
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 32768
net.ipv4.tcp_fin_timeout = 30

# --- 协议栈特性 ---
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
EOF

    # --- 步骤 3: 如果支持 BBR，追加配置并加载模块 ---
    if [ "$enable_bbr" = true ]; then
        cat >> "$SYSCTL_CUSTOM_FILE" << EOF

# --- 核心 BBR 拥塞控制 ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
        # 尝试加载模块
        modprobe tcp_bbr >/dev/null 2>&1
    fi

    # --- 步骤 4: 应用参数 ---
    print_step "正在重载内核参数..."
    if sysctl -p "$SYSCTL_CUSTOM_FILE" >/dev/null 2>&1; then
        print_success "高性能优化已生效！"
        if [ "$enable_bbr" = true ]; then
            print_echo "   拥塞控制: ${GREEN}BBR 已开启${NC}"
        else
            print_echo "   拥塞控制: ${YELLOW}未开启 (内核不支持)${NC}"
        fi
    else
        print_error "应用部分参数失败，请检查系统日志。"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 逻辑 2: 恢复系统默认 (最彻底的恢复)
# ------------------------------------------------------------------------------
restore_default_tuning() {
    print_clear
    print_box_info -m "恢复系统默认网络设置"
    
    if [[ ! -f "$SYSCTL_CUSTOM_FILE" ]]; then
        print_info "未检测到脚本生成的优化文件，无需恢复。"
        print_wait_enter
        return
    fi

    print_echo "${YELLOW}逻辑说明：${NC}此操作将删除优化脚本，重载 Linux 默认参数。"
    print_echo "建议您先去【备份管理】确认是否有手动备份。"
    
    local confirm
    confirm=$(read_choice -s 1 -m "确认恢复默认? [y/N]")
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        # 恢复前也可以做一个备份，以防万一
        _perform_backup "auto_before_restore"
        
        rm -f "$SYSCTL_CUSTOM_FILE"
        # 尝试移除持久化加载配置(如果有)
        rm -f /etc/modules-load.d/bbr.conf 2>/dev/null
        
        print_step "正在重载系统默认参数..."
        sysctl --system >/dev/null 2>&1
        print_success "已恢复系统初始状态。"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 逻辑 3: 手动备份
# ------------------------------------------------------------------------------
manual_backup_config() {
    print_clear
    print_box_info -m "手动备份当前配置"
    _perform_backup "manual"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 逻辑 4: 查看生效参数 (BBR + 关键参数)
# ------------------------------------------------------------------------------
view_tuning_status() {
    print_clear
    print_box_header "当前网络参数状态"
    
    local cc
    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    print_echo "${BOLD_CYAN}拥塞控制 (Congestion):${NC} ${cc}"
    
    print_echo "${BOLD_CYAN}队列调度 (Qdisc):${NC} $(sysctl -n net.core.default_qdisc 2>/dev/null)"
    print_echo "${BOLD_CYAN}IP 转发 (Forward):${NC} $(sysctl -n net.ipv4.ip_forward 2>/dev/null)"
    print_echo "${BOLD_CYAN}发送缓冲区 (Wmem Max):${NC} $(sysctl -n net.core.wmem_max 2>/dev/null)"
    
    print_line
    if [[ "$cc" == "bbr" ]]; then
        print_echo "${GREEN}✔ BBR 正在运行中${NC}"
    else
        print_echo "${YELLOW}✖ BBR 未运行${NC}"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 逻辑 5: 备份管理
# ------------------------------------------------------------------------------
manage_backups() {
    print_clear
    print_box_info -m "配置备份管理"
    
    print_echo "备份存放路径: ${CYAN}${BACKUP_DIR}${NC}"
    print_line
    
    # 检查目录下是否有匹配 sysctl_ 的文件，避免 ls 报错
    # 这里的 glob 会自动扩展，如果找不到文件，ls 会报错到 /dev/null
    if ! ls "$BACKUP_DIR"/sysctl_* 1> /dev/null 2>&1; then
        print_echo "${GRAY}   (暂无备份文件)${NC}"
    else
        # --- 1. 打印表头 ---
        printf "   ${BOLD_CYAN}%-45s %-10s %-20s${NC}\n" "文件名" "大小" "创建时间"
        
        # --- 2. 打印分割线 ---
        print_echo "${GRAY}   -----------------------------------------------------------------------------${NC}"
        
        # --- 3. 打印数据 (优化版) ---
        # 核心修改：直接列出目标文件 "$BACKUP_DIR"/sysctl_*
        # awk 说明：$8=文件名(ls全路径需要处理), $5=大小, $6$7=时间
        # 为了只显示文件名而不是全路径，awk 中使用了 split 或者是 basename 的逻辑，
        # 但由于 ls -lh 输出的是纯文件名(不带路径)吗？取决于 ls 的行为。
        # ls -lh 加上路径参数时，通常会输出全路径。
        # 所以这里最稳妥的方式是先 cd 进去，或者用 awk 处理路径。
        
        (cd "$BACKUP_DIR" && ls -lh --time-style=long-iso sysctl_* 2>/dev/null) | \
        sort -r | head -n 10 | \
        awk '{printf "   %-42s %-8s %s %s\n", $8, $5, $6, $7}'
        
        print_line
        
        # --- 4. 底部提示 ---
        # 场景 A: 不需要 # 号 (你现在的代码)
        print_box_header_tip "$(print_spaces 1)✦$(print_spaces 1)如需恢复特定备份，请使用 cat 命令覆盖 /etc/sysctl.conf"
        
        # 场景 B: 如果你想要 # 号，就写成: 
        # print_box_header_tip -h " 这是一个带井号的提示"

        print_echo "   例如: cat .../文件名 > /etc/sysctl.conf && sysctl -p"
    fi
    
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 逻辑 6: 删除备份 (交互式删除)
# ------------------------------------------------------------------------------
delete_backup() {
    print_clear
    print_box_info -m "删除备份文件"
    
    # 检查是否有文件 (使用 glob 防止 ls 报错)
    if ! ls "$BACKUP_DIR"/sysctl_* 1> /dev/null 2>&1; then
        print_echo "${GRAY}   (暂无备份文件，无需删除)${NC}"
        print_wait_enter
        return
    fi

    # 生成文件数组 (倒序排列: 最新的在前)
    # 使用圆括号 () 将 ls 的结果转化为 bash 数组
    local files=()
    mapfile -t files < <(ls -r "$BACKUP_DIR"/sysctl_* 2>/dev/null)
    
    print_echo "${BOLD_CYAN}请选择要删除的备份文件:${NC}"
    
    # 遍历数组并显示带编号的列表
    local i=1
    for filepath in "${files[@]}"; do
        # 获取纯文件名
        local filename
        filename=$(basename "$filepath")
        # 显示格式: [1] sysctl_xxx.conf
        print_echo "   [${i}] ${filename}"
        ((i++))
    done
    
    print_line
    # 交互输入
    local choice
    read -e -r -p "➜ 请输入要删除的文件编号 (0 取消): " choice
    
    # 逻辑判断
    if [[ "$choice" == "0" || -z "$choice" ]]; then
        print_info -m "操作已取消"
        return
    fi
    
    # 验证是否为纯数字
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        print_error "请输入有效的数字！"
        print_wait_enter
        return
    fi
    
    # 验证数字范围
    if [[ "$choice" -lt 1 || "$choice" -gt ${#files[@]} ]]; then
        print_error "编号超出范围！"
        print_wait_enter
        return
    fi
    
    # 根据编号找到对应的文件 (数组下标从0开始，所以要减1)
    local target_file="${files[$((choice-1))]}"
    local target_name
    target_name=$(basename "$target_file")
    
    print_line
    # 二次确认
    local confirm
    confirm=$(read_choice -s 1 -m "确认永久删除 ${RED}${target_name}${NC}? [y/N]")
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -f "$target_file"
        print_success "文件已删除。"
    else
        print_info "操作已取消。"
    fi
    print_wait_enter
}