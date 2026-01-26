#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - Tmux 终端复用管理
#
# @文件路径: modules/basic/tmux/tmux.sh
# @功能描述: 提供 Tmux 管理 (强制使用 /var/run Socket 穿透隔离)
# ==============================================================================

# ==============================================================================
# 核心配置: 穿透隔离专用 Socket
# ==============================================================================
# Systemd 默认隔离了 /tmp，导致 SSH 和 Agent 互不相见。
# 改用 /var/run，这是一个所有 Root 进程都能看到的公共区域，完美解决隔离问题。
TMUX_SOCK="/var/run/tmux-vpsscriptkit-shared.sock"

# ------------------------------------------------------------------------------
# 内部函数: 检查并安装 Tmux
# ------------------------------------------------------------------------------
_check_tmux_installed() {
    if command -v tmux &> /dev/null; then
        return 0
    fi
    print_box_info -m "检测到系统未安装 Tmux，正在为您安装..."
    pkg_install tmux
    if ! command -v tmux &> /dev/null; then
        print_error "Tmux 安装失败，请检查包管理器设置。"
        print_wait_enter
        return 1
    fi
    print_box_success -m "Tmux 安装成功！"
    sleep 1
    return 0
}

# ------------------------------------------------------------------------------
# 内部函数: 获取会话列表
# ------------------------------------------------------------------------------
_get_session_list_formatted() {
    if ! command -v tmux &> /dev/null; then return; fi
    
    # 检查是否有会话 (使用指定 Socket)
    if ! tmux -S "$TMUX_SOCK" list-sessions 2>/dev/null | grep -q ":"; then
        echo "${GREY}   (当前无运行中的会话)${NC}"
        return
    fi

    # 遍历获取数据 (使用指定 Socket)
    tmux -S "$TMUX_SOCK" list-sessions -F "#{session_name}|#{?session_attached,1,0}|#{session_windows}|#{session_created}" | while IFS='|' read -r name is_attached win_count created_ts; do
        
        # --- 1. 状态显示 ---
        local status_str
        if [[ "$is_attached" == "1" ]]; then
            status_str="${GREEN}[● 活跃]${NC}"
        else
            status_str="${GREY}[○ 后台]${NC}"
        fi

        # --- 2. 窗口显示 ---
        local win_str="${GREY}[${win_count} windows]${NC}"

        # --- 3. 时间显示 ---
        local date_str="-"
        if [[ -n "$created_ts" ]]; then
            date_str=$(date -d "@$created_ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        fi
        local time_display="${GREY}${date_str}${NC}"

        # --- 4. 名字与虚线处理 ---
        local left_width=30
        local display_name="$name"
        if [[ ${#display_name} -gt $((left_width - 3)) ]]; then
            display_name="${display_name:0:$((left_width - 4))}…"
        fi
        local dot_count=$(( left_width - ${#display_name} ))
        if [[ $dot_count -lt 2 ]]; then dot_count=2; fi
        local dots=""
        for ((i=0; i<dot_count; i++)); do dots="${dots}."; done
        local dots_display="${GREY}${dots}${NC}"

        # --- 5. 输出 ---
        printf "   ${CYAN}%s${NC} %s %s %s %s\n" "$display_name" "$dots_display" "$status_str" "$win_str" "$time_display"
    done
}

# ------------------------------------------------------------------------------
# 内部函数: 检查 SSH 常驻状态
# ------------------------------------------------------------------------------
_check_ssh_persistent_status() {
    if grep -q "# VpsScriptKit-AutoTmux" ~/.bashrc; then
        return 0 
    else
        return 1 
    fi
}

# ------------------------------------------------------------------------------
# 功能 21: SSH 常驻模式 (带 Socket)
# ------------------------------------------------------------------------------
tmux_ssh_persistent_ui() {
    print_clear
    print_box_info -m "SSH 常驻模式配置"
    print_echo "开启后，SSH 连接将自动进入名为 'sshd' 的会话。"
    print_echo "${YELLOW}注：已配置 Socket 穿透，确保 Agent/SSH 互通。${NC}"
    
    local current_status
    if _check_ssh_persistent_status; then
        current_status="${GREEN}已开启${NC}"
    else
        current_status="${GREY}已关闭${NC}"
    fi
    print_echo "当前状态: ${current_status}"
    print_line

    print_menu_item -r 1 -p 0 -i 1 -m "开启常驻模式"
    print_menu_item -r 1 -p 12 -i 2 -m "关闭常驻模式"
    print_menu_go_level
    
    local choice
    choice=$(read_choice)
    case "$choice" in
        1)
            if _check_ssh_persistent_status; then
                print_info "已经是开启状态。"
            else
                print_step "正在配置 ~/.bashrc ..."
                # 写入配置：必须显式指定 -S Socket
                cat << EOF >> ~/.bashrc

# VpsScriptKit-AutoTmux
if [[ -z "\$TMUX" && -n "\$SSH_CONNECTION" ]]; then
    tmux -S "$TMUX_SOCK" attach-session -t sshd || tmux -S "$TMUX_SOCK" new-session -s sshd
fi
EOF
                print_success "SSH 常驻模式已开启！"
            fi
            ;;
        2)
            if ! _check_ssh_persistent_status; then
                print_info "已经是关闭状态。"
            else
                print_step "正在清理 ~/.bashrc ..."
                sed -i '/# VpsScriptKit-AutoTmux/,+5d' ~/.bashrc
                
                # 尝试关闭对应的 Socket 下的 sshd 会话
                if tmux -S "$TMUX_SOCK" has-session -t sshd 2>/dev/null; then
                     local kill_now
                     kill_now=$(read_choice -s 1 -m "是否同时也关闭后台运行的 sshd 会话? [y/N]")
                     if [[ "$kill_now" == "y" ]]; then
                        tmux -S "$TMUX_SOCK" kill-session -t sshd 2>/dev/null
                        print_success "后台 sshd 会话已关闭。"
                     fi
                fi
                print_success "SSH 常驻模式已关闭！"
            fi
            ;;
        0) return ;;
    esac
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 功能 22: 创建/进入会话 (带 Socket)
# ------------------------------------------------------------------------------
tmux_create_or_attach_ui() {
    print_clear
    print_box_info -s start -m "创建 / 进入会话"
    
    print_echo "${BOLD_CYAN}当前会话:${NC}"
    _get_session_list_formatted
    print_line
    
    print_echo "请输入会话名称 (例如: run, test, 1)"
    print_echo "逻辑: 存在则进入，不存在则创建。"
    
    local name
    name=$(read_choice -s 1 -m "会话名称")
    if [[ -z "$name" || "$name" == "0" ]]; then
        print_info -m "操作已取消"
        print_wait_enter
        return 0;
    fi

    if tmux -S "$TMUX_SOCK" has-session -t "$name" 2>/dev/null; then
        print_step "会话 [$name] 已存在，正在接入..."
        sleep 0.5
        
        if [[ -n "${TMUX:-}" ]]; then
            tmux -S "$TMUX_SOCK" switch-client -t "$name"
        else
            tmux -S "$TMUX_SOCK" attach-session -t "$name"
        fi
    else
        print_step "会话 [$name] 不存在，正在创建并接入..."
        sleep 0.5
        
        if [[ -n "${TMUX:-}" ]]; then
            tmux -S "$TMUX_SOCK" new-session -d -s "$name"
            tmux -S "$TMUX_SOCK" switch-client -t "$name"
        else
            tmux -S "$TMUX_SOCK" new-session -s "$name"
        fi
    fi
    print_clear
}

# ------------------------------------------------------------------------------
# 功能 24: 关闭会话
# ------------------------------------------------------------------------------
tmux_kill_session_ui() {
    print_clear
    print_box_info -s start -m "关闭会话 (Kill)"
    print_echo "${BOLD_CYAN}当前会话:${NC}"
    _get_session_list_formatted
    print_line
    
    local name
    name=$(read_choice -s 1 -m "请输入要关闭的会话名称")
    if [[ -z "$name" || "$name" == "0" ]]; then
        print_info -m "操作已取消"
        print_wait_enter
        return 0
    fi

    if tmux -S "$TMUX_SOCK" kill-session -t "$name" 2>/dev/null; then
        print_success "会话 [$name] 已终止。"
    else
        print_error "关闭失败，会话可能不存在。"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 功能 25: 注入命令到后台 (带 Socket)
# ------------------------------------------------------------------------------
tmux_inject_command_ui() {
    print_clear
    print_box_info -s start -m "注入命令到后台会话"
    print_echo "此功能将创建一个新的后台会话，并自动执行您输入的命令。"
    
    local session_name
    session_name=$(read_choice -s 1 -m "1. 定义会话名称 (如 task1)")
    if [[ -z "$session_name" ]]; then print_info -m "操作已取消"; return 0; fi
    
    local user_cmd
    print_echo "2. 请输入完整命令 (支持管道/脚本，如: ping 1.1.1.1):"
    read -e -r -p "➜ 命令: " user_cmd
    [[ -z "$user_cmd" ]] && return 0
    
    print_line
    run_in_tmux_guard "$session_name" "$user_cmd"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 功能 26: 清空所有
# ------------------------------------------------------------------------------
tmux_kill_server_ui() {
    print_clear
    print_box_info -m "清空所有 Tmux 会话"
    print_echo "${RED}警告：这将强制结束所有正在运行的后台任务！${NC}"
    
    local confirm
    confirm=$(read_choice -s 1 -m "确认清空? [yes/no]")
    
    if [[ "$confirm" == "yes" ]]; then
        tmux -S "$TMUX_SOCK" kill-server 2>/dev/null
        print_success "Tmux 服务已重置，所有会话已清除。"
    else
        print_info "操作已取消。"
    fi
    print_wait_enter
}

# ==============================================================================
# 核心 API: 执行保护器 (供外部脚本调用)
# ==============================================================================
run_in_tmux_guard() {
    local session_name="$1"
    local cmd="$2"

    if [[ -n "${TMUX:-}" ]]; then
        eval "$cmd"
        return
    fi

    if ! command -v tmux &> /dev/null; then
        print_warn "未安装 Tmux，正在尝试安装..."
        pkg_install tmux
        if ! command -v tmux &> /dev/null; then
             print_error "安装失败，直接运行命令。"
             eval "$cmd"
             return
        fi
    fi

    print_box_info -m "防断连保护模式"
    print_echo "即将创建后台会话 [${session_name}] 执行任务。"
    print_echo "如果 SSH 断开，任务依然会在后台运行。"
    
    local use_tmux
    use_tmux=$(read_choice -s 1 -m "是否开启保护? [Y/n]")
    
    if [[ "$use_tmux" == "n" || "$use_tmux" == "N" ]]; then
        eval "$cmd"
        return
    fi

    local final_cmd="$cmd; echo ''; echo '--------------------------------'; read -p '任务执行完毕，按回车键退出窗口...' key; exit"
    
    # 使用 Socket 检查重名
    if tmux -S "$TMUX_SOCK" has-session -t "$session_name" 2>/dev/null; then
        session_name="${session_name}_$(date +%s)"
    fi
    
    print_step "正在初始化后台环境 ($session_name)..."
    # 后台创建 (带 Socket)
    tmux -S "$TMUX_SOCK" new-session -d -s "$session_name" "bash -c \"$final_cmd\""
    sleep 1
    # 接入 (带 Socket)
    tmux -S "$TMUX_SOCK" attach-session -t "$session_name"
}

# ==============================================================================
# 菜单入口函数
# ==============================================================================
tmux_ui_menu() {
    print_clear

    if ! _check_tmux_installed; then return; fi

    while true; do
        print_clear
        print_box_header "${ICON_GEAR}$(print_spaces 1)Tmux 终端复用管理 (Tmux Manager)"
        print_line
        print_box_header_tip "$(print_spaces 1)✦$(print_spaces 1)进入会话后使用 Ctrl+b 再单独按 d，退出当前会话！"
        print_line
        
        print_echo "${BOLD_CYAN}当前运行中的会话列表:${NC}"
        _get_session_list_formatted
        print_line

        local ssh_status_icon=""
        if _check_ssh_persistent_status; then
            ssh_status_icon="${GREEN}[开启]${NC}"
        else
            ssh_status_icon="${GREY}[关闭]${NC}"
        fi
        
        print_menu_item -r 21 -p 0 -i 21 -m "SSH 常驻模式 ${ssh_status_icon}"
        print_menu_item -r 22 -p 0 -i 22 -m "创建/进入会话"
        print_menu_item -r 23 -p 0 -i 23 -m "查看列表 (刷新)"
        print_menu_item -r 24 -p 0 -i 24 -m "关闭会话"
        print_menu_item -r 25 -p 0 -i 25 -m "注入命令到后台会话"
        print_menu_item -r 26 -p 0 -i 26 -m "${RED}清空所有会话${NC}"
        print_menu_item_done

        print_menu_go_level

        local choice
        choice=$(read_choice)

        case "$choice" in
            21) tmux_ssh_persistent_ui ;;
            22) tmux_create_or_attach_ui ;;
            23) : ;;
            24) tmux_kill_session_ui ;;
            25) tmux_inject_command_ui ; print_wait_enter ;;
            26) tmux_kill_server_ui ;;
            0) return ;;
            *) print_error "无效选项"; sleep 1 ;;
        esac
    done
}