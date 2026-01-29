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
    kernel_version=$(uname -r | cut -d. -f1,2)
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
             # 自动备份静默执行，只打印一行小字
             print_echo "${GRAY}   [系统] 已自动创建配置备份: ${filename}${NC}"
        fi
    fi
}

# ==============================================================================
# 辅助函数: 确保 Swap 容量 (兜底神器)
# ==============================================================================
_ensure_swap_capability() {
    local target_swap_mb="$1" # 期望的 swap 大小，例如 1024
    
    # 获取当前 Swap (MB)
    local current_swap_kb
    current_swap_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    local current_swap_mb=$((current_swap_kb / 1024))
    
    # 如果当前 Swap 足够大 (例如大于 900MB 就算达标)，直接返回
    if (( current_swap_mb >= (target_swap_mb - 100) )); then
        return 0
    fi
    
    print_warn "当前模式需要至少 ${target_swap_mb}MB Swap 兜底 (当前: ${current_swap_mb}MB)"
    print_step "正在调用 Swap 模块进行自动补全..."
    
    local swap_script="${BASE_DIR}/modules/system/memory/swap.sh"
    if [[ -f "$swap_script" ]]; then
        # shellcheck disable=SC1090
        source "$swap_script"
        # 调用 swap.sh 的 create 函数
        swap_create "$target_swap_mb"
    else
        print_error "未找到 Swap 脚本，无法自动补全！存在 OOM 风险。"
        print_echo "建议手动先去【基础工具】开启 Swap。"
        sleep 3
    fi
}

# ==============================================================================
# 1. TCP 调优
# ==============================================================================
apply_performance_tuning() {
    while true; do
        print_clear
        print_box_info -m "选择 TCP 调优模式"
        
        print_echo "${BOLD_CYAN}1. 暴力模式 (Force High Performance)${NC}"
        print_echo "   - 适用: 你明确知道自己在做什么，或者追求极致速度。"
        print_echo "   - 策略: 强制使用 64MB 大缓冲区 (Oracle标准)。"
        print_echo "   - 保障: 脚本会自动检测并创建 Swap 以防止 OOM。"
        print_line
        
        print_echo "${BOLD_CYAN}2. 智能激进模式 (Smart Aggressive)${NC}"
        print_echo "   - 适用: 不确定 VPS 配置，希望系统自动判断最优解。"
        print_echo "   - 策略: 根据内存动态调整。小内存给足(激进)，大内存拉满。"
        print_echo "   - 保障: 自动平衡资源占用与网络性能。"
        print_line
        
        local mode
        mode=$(read_choice -m "请选择模式 [1/2]（输入 0 退出）" -s 2)
        
        case "$mode" in
            1) 
                if _apply_profile_force_high; then
                    return
                fi
                ;;
            2)
                if _apply_profile_smart; then
                    return
                fi
            ;;
            0)
                return
                ;;
            *)
                print_error -m "无效选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# 辅助: 写入系统级 Limit (ulimit/systemd)
# 作用: 确保程序能打开足够多的文件句柄 (100万)
# ==============================================================================
_optimize_system_limits() {
    print_step "正在解除系统最大文件打开数限制 (ulimit)..."
    
    # 1. 修改 limits.conf (对普通进程生效)
    if grep -q "soft nofile" /etc/security/limits.conf; then
        sed -i '/soft nofile/d' /etc/security/limits.conf
        sed -i '/hard nofile/d' /etc/security/limits.conf
    fi

    {
        echo "* soft nofile 1000000"
        echo "* hard nofile 1000000"
        echo "root soft nofile 1000000"
        echo "root hard nofile 1000000"
    } >> /etc/security/limits.conf

    # 2. 修改 systemd 全局配置 (对服务进程生效)
    local sys_conf="/etc/systemd/system.conf"
    local user_conf="/etc/systemd/user.conf"

    for conf in "$sys_conf" "$user_conf"; do
        if [[ -f "$conf" ]]; then
            sed -i '/DefaultLimitNOFILE/d' "$conf"
            echo "DefaultLimitNOFILE=1000000" >> "$conf"
        fi
    done
    
    # 3. 实时生效当前 Shell (防止报错)
    ulimit -n 1000000 2>/dev/null || true
}

# ==============================================================================
# 核心通用: 写入 Sysctl 配置文件 (接收动态参数)
# ==============================================================================
_write_sysctl_config() {
    local p_name="$1"
    local p_rmem="$2"      # TCP 读缓冲区
    local p_wmem="$3"      # TCP 写缓冲区
    local p_min_free="$4"  # 内存预留
    local p_conntrack="$5" # 连接追踪数

    # --- 1. 强制备份 ---
    print_step "执行安全备份..."
    _perform_backup "auto"
    
    # --- 2. 解锁系统 Limits ---
    _optimize_system_limits
    
    # --- 3. BBR 检查 ---
    local enable_bbr=true
    if ! _check_kernel_support_bbr; then
        print_warn "内核不支持 BBR，仅优化 TCP 参数。"
        enable_bbr=false
    fi

    # --- 4. 预加载内核模块 ---
    print_step "正在预加载内核模块..."
    modprobe nf_conntrack 2>/dev/null || true
    modprobe nf_conntrack_ipv4 2>/dev/null || true
    modprobe nf_conntrack_ipv6 2>/dev/null || true

    print_step "正在写入内核配置: $(print_echo "$p_name" | sed 's/\x1b\[[0-9;]*m//g')..."
    
    cat > "$SYSCTL_CUSTOM_FILE" << EOF
# ============================================================
# VpsScriptKit TCP Tuning
# 策略: $(print_echo "$p_name" | sed 's/\x1b\[[0-9;]*m//g')
# 时间: $(date)
# ============================================================

# --- 系统级打开文件数 (100万) ---
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

# --- 系统稳定性 ---
kernel.pid_max = 65535
vm.panic_on_oom = 0
vm.swappiness = 20
vm.min_free_kbytes = $p_min_free

# --- TCP 缓冲区 (动态: $((p_rmem/1024/1024)) MB) ---
net.core.rmem_max = $p_rmem
net.core.wmem_max = $p_wmem
net.ipv4.tcp_rmem = 4096 87380 $p_rmem
net.ipv4.tcp_wmem = 4096 65536 $p_wmem
net.ipv4.tcp_window_scaling = 1

# --- 连接追踪与并发 (动态: $p_conntrack) ---
# 防火墙连接表大小 (已移除过时的 ipv4.netfilter 参数)
net.netfilter.nf_conntrack_max = $p_conntrack
# 连接超时优化
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_established = 300

# --- ARP 缓存 ---
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 4096

# --- 端口范围 (扩大) ---
net.ipv4.ip_local_port_range = 10000 65535

# --- 低延迟与转发 ---
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.ip_forward = 1
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 16384
net.ipv4.tcp_max_syn_backlog = 8192

# --- 连接回收 ---
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 16384
net.ipv4.tcp_fin_timeout = 30

# --- 协议栈特性 ---
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
EOF

    # --- 5. 追加拥塞控制 ---
    if [ "$enable_bbr" = true ]; then
        cat >> "$SYSCTL_CUSTOM_FILE" << EOF

# --- BBR 拥塞控制 ---
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
        modprobe tcp_bbr >/dev/null 2>&1
        echo "tcp_bbr" > /etc/modules-load.d/bbr.conf 2>/dev/null
    else
        cat >> "$SYSCTL_CUSTOM_FILE" << EOF

# --- Cubic 拥塞控制 (Fallback) ---
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = cubic
EOF
    fi

    # --- 6. 重新加载 ---
    local apply_output
    if apply_output=$(sysctl -p "$SYSCTL_CUSTOM_FILE" 2>&1); then
        print_success "调优成功！"
        print_echo "   当前策略: $p_name"
        print_echo "   最大连接数(Conntrack): ${CYAN}$p_conntrack${NC}"
        print_echo "   系统句柄(File-Max): ${CYAN}1,000,000${NC}"
        print_wait_enter
        return 0
    else
        print_error "应用失败！内核拒绝了部分参数。"
        print_line
        print_echo "${YELLOW}=== 错误详情 (Sysctl Error) ===${NC}"
        # 只显示报错的行
        echo "$apply_output" | grep "error" -A 1 || echo "$apply_output"
        print_line
        print_echo "${ICON_TIP} 提示: 这通常是因为 VPS 虚拟化架构限制 (如 OpenVZ/LXC) 或内核模块未加载。"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 模式 A: 暴力模式 (Force High)
# ------------------------------------------------------------------------------
_apply_profile_force_high() {
    print_clear
    print_box_info -m "正在应用: 暴力高性能模式"
    
    # 暴力模式: 必须有 1G Swap
    _ensure_swap_capability 1024
    
    # 参数定义
    local tcp_rmem_max=67108864   # 64MB 缓冲
    local tcp_wmem_max=67108864
    local min_free_kb=65536       # 64MB 预留
    local conntrack_max=1000000   # 100万连接追踪 (暴力拉满)
    
    local profile_name="${RED}暴力高性能 (Force High)${NC}"

    # 传递 5 个参数
    _write_sysctl_config "$profile_name" "$tcp_rmem_max" "$tcp_wmem_max" "$min_free_kb" "$conntrack_max"
}

# ------------------------------------------------------------------------------
# 模式 B: 智能激进模式 (Smart Aggressive)
# ------------------------------------------------------------------------------
_apply_profile_smart() {
    print_clear
    print_box_info -m "正在应用: 智能激进模式"
    
    local mem_total_kb
    mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_total_mb=$((mem_total_kb / 1024))
    
    local tcp_rmem_max tcp_wmem_max min_free_kb conntrack_max profile_name

    # 判定逻辑 (分界线 900MB)
    if (( mem_total_mb >= 900 )); then
        # [大内存 > 900MB]
        print_echo "检测到内存 > 900MB，启用高性能配置。"
        _ensure_swap_capability 1024
        
        tcp_rmem_max=67108864  # 64MB
        tcp_wmem_max=67108864
        min_free_kb=131072     # 128MB 预留
        conntrack_max=524288   # 52万连接 (比100万安全，省点内存)
        
        profile_name="${GREEN}🚀 智能高性能 (Smart High)${NC}"
    else
        # [小内存 < 900MB]
        print_echo "检测到小内存，启用激进平衡配置。"
        _ensure_swap_capability 1024
        
        tcp_rmem_max=16777216  # 16MB (足够跑满 G 口)
        tcp_wmem_max=16777216
        min_free_kb=65536      # 64MB 预留
        conntrack_max=65536    # 6.5万连接 (小内存安全线，再大容易 OOM)
        
        profile_name="${YELLOW}⚡ 智能优化 (Smart Balanced)${NC}"
    fi
    
    # 传递 5 个参数
    _write_sysctl_config "$profile_name" "$tcp_rmem_max" "$tcp_wmem_max" "$min_free_kb" "$conntrack_max"
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
# 逻辑 4: 查看生效参数 (支持颜色代码的完美对齐版)
# ------------------------------------------------------------------------------
view_tuning_status() {
    print_clear
    
    # --- 单位转换工具 ---
    calc_mb() {
        local val="$1"
        local clean_val
        clean_val=$(echo "$val" | tr -cd '0-9')
        if [[ -n "$clean_val" && "$clean_val" -gt 1024 ]]; then
            echo "$((clean_val / 1024 / 1024)) MB"
        else
            echo "$val"
        fi
    }
    
    calc_kb_mb() {
        local val="$1"
        local clean_val
        clean_val=$(echo "$val" | tr -cd '0-9')
        if [[ -n "$clean_val" && "$clean_val" -gt 1024 ]]; then
            echo "$((clean_val / 1024)) MB"
        else
            echo "$val"
        fi
    }

    get() {
        local val
        val=$(sysctl -n "$1" 2>/dev/null)
        if [[ -z "$val" ]]; then echo "N/A"; else echo "$val"; fi
    }

    # --- 准备数据 ---
    local cc
    cc=$(get net.ipv4.tcp_congestion_control)
    local qdisc
    qdisc=$(get net.core.default_qdisc)
    local ip_fwd
    ip_fwd=$(get net.ipv4.ip_forward)
    local fastopen
    fastopen=$(get net.ipv4.tcp_fastopen)
    
    local file_max
    file_max=$(get fs.file-max)
    local ct_max
    ct_max=$(get net.netfilter.nf_conntrack_max)
    local somax
    somax=$(get net.core.somaxconn)
    local port_range
    port_range=$(get net.ipv4.ip_local_port_range)
    
    local rmem
    rmem=$(calc_mb "$(get net.core.rmem_max)")
    local wmem
    wmem=$(calc_mb "$(get net.core.wmem_max)")
    local min_free
    min_free=$(calc_kb_mb "$(get vm.min_free_kbytes)")
    local swappiness
    swappiness=$(get vm.swappiness)
    
    local reuse
    reuse=$(get net.ipv4.tcp_tw_reuse)
    local fin_to
    fin_to=$(get net.ipv4.tcp_fin_timeout)
    local sack
    sack=$(get net.ipv4.tcp_sack)
    local tw_buckets
    tw_buckets=$(get net.ipv4.tcp_max_tw_buckets)

    # --- 渲染配置 ---
    local L_W=16   # 标签宽度
    local V_W=20   # 左侧数值预留宽度 (挤开右侧列)
    local PAD=0    # 左侧缩进 (对应原本的 print_row 里的空格)

    print_box_header "当前系统内核参数状态 (System Parameters)"
    
    # ▶ 核心控制
    print_echo "${BOLD_YELLOW}${ICON_NAV} 核心控制 (Core & Congestion)${NC}"
    # Row 0
    print_status_item -r 0 -p "$PAD" -l "拥塞控制:" -v "${CYAN}${cc}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 0 -l "队列调度:" -v "${CYAN}${qdisc}${NC}" -w "$L_W"
    # Row 1
    print_status_item -r 1 -p "$PAD" -l "IP转发:" -v "${CYAN}${ip_fwd}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 1 -l "快速打开:" -v "${CYAN}${fastopen}${NC}" -w "$L_W"
    # 结束块
    print_status_done
    print_line -c "─" -C "${GRAY}"

    # ▶ 容量限制
    print_echo "${BOLD_YELLOW}${ICON_NAV} 容量限制 (Capacity & Limits)${NC}"
    # Row 0 (重置行号从0开始，视觉上更清晰)
    print_status_item -r 0 -p "$PAD" -l "系统文件句柄:" -v "${CYAN}${file_max}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 0 -l "连接追踪上限:" -v "${CYAN}${ct_max}${NC}" -w "$L_W"
    # Row 1
    print_status_item -r 1 -p "$PAD" -l "监听队列:" -v "${CYAN}${somax}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 1 -l "本地端口范围:" -v "${CYAN}${port_range}${NC}" -w "$L_W"
    # 结束块
    print_status_done
    print_line -c "─" -C "${GRAY}"

    # ▶ 内存与缓冲
    print_echo "${BOLD_YELLOW}${ICON_NAV} 内存与缓冲 (Memory & Buffers)${NC}"
    # Row 0
    print_status_item -r 0 -p "$PAD" -l "接收缓冲(Rmem):" -v "${CYAN}${rmem}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 0 -l "发送缓冲(Wmem):" -v "${CYAN}${wmem}${NC}" -w "$L_W"
    # Row 1
    print_status_item -r 1 -p "$PAD" -l "内存预留:" -v "${CYAN}${min_free}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 1 -l "Swap积极性:" -v "${CYAN}${swappiness}${NC}" -w "$L_W"
    # 结束块
    print_status_done
    print_line -c "─" -C "${GRAY}"

    # ▶ 协议特性
    print_echo "${BOLD_YELLOW}${ICON_NAV} 协议特性 (Features & Recycle)${NC}"
    # Row 0
    print_status_item -r 0 -p "$PAD" -l "TimeWait重用:" -v "${CYAN}${reuse}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 0 -l "FIN超时时间:" -v "${CYAN}${fin_to}s${NC}" -w "$L_W"
    # Row 1
    print_status_item -r 1 -p "$PAD" -l "SACK确认:" -v "${CYAN}${sack}${NC}" -w "$L_W" -W "$V_W"
    print_status_item -r 1 -l "TW桶最大值:" -v "${CYAN}${tw_buckets}${NC}" -w "$L_W"
    # 结束块
    print_status_done
    print_line -c "─" -C "${GRAY}"

    # 底部状态检查
    if [[ "$cc" == *bbr* ]]; then
         print_echo "${GREEN}✔ BBR 拥塞控制正在运行中${NC}"
    else
         print_echo "${RED}✖ BBR 未激活${NC} ${YELLOW}(当前使用: $cc)${NC}"
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
    if ! ls "$BACKUP_DIR"/sysctl_* 1> /dev/null 2>&1; then
        print_echo "${GRAY}   (暂无备份文件)${NC}"
    else
        # --- 1. 打印表头 ---
        printf "   ${BOLD_CYAN}%-45s %-10s %-20s${NC}\n" "文件名" "大小" "创建时间"
        
        # --- 2. 打印分割线 ---
        print_line -c "-" -C "${GRAY}"
        
        # --- 3. 打印数据 ---
        (cd "$BACKUP_DIR" && ls -lh --time-style=long-iso sysctl_* 2>/dev/null) | \
        sort -r | head -n 10 | \
        awk '{printf "   %-42s %-8s %s %s\n", $8, $5, $6, $7}'
        
        print_line
        
        # --- 4. 底部提示 ---
        print_box_header_tip "$(print_spaces 1)${ICON_TIP}$(print_spaces 1)如需恢复特定备份，请使用 cat 命令覆盖 /etc/sysctl.conf"
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