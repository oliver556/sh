#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 命令行终端美化 - 入口
#
# @文件路径: modules/system/terminal/terminal_tuning.sh
# @功能描述: 命令行终端美化 - 子菜单
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-01
# ==============================================================================

# ------------------------------------------------------------------------------
# 内部函数: 设置 PS1 (写入 .profile 以确保 SSH 断连即生效)
# ------------------------------------------------------------------------------
_set_ps1() {
    local ps1_str="$1"
    local target_file=""

    # 1. 精准定位配置文件 (Debian/Ubuntu 优先 .profile)
    if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
        target_file="$HOME/.bashrc"
    else
        target_file="$HOME/.profile"
    fi
    
    # 2. 备份
    cp "$target_file" "${target_file}.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    
    # 3. 清理旧配置 (先删再写)
    _clean_ps1_config_internal "$target_file"
    
    # 4. 写入新配置
    echo "PS1='${ps1_str}' # VpsScriptKit-Prompt" >> "$target_file"
    
    # 5. 双重保险: 同步 .bashrc (防止非登录 Shell 不生效)
    if [[ "$target_file" != "$HOME/.bashrc" ]]; then
        local bashrc="$HOME/.bashrc"
        # 仅清理旧标记，避免重复
        sed -i '/# VpsScriptKit-Prompt/d' "$bashrc" 2>/dev/null
        echo "PS1='${ps1_str}' # VpsScriptKit-Prompt" >> "$bashrc"
    fi
    
    print_success "终端美化配置已写入: ${CYAN}${target_file}${NC}"
    print_echo "${YELLOW}提示：${NC}请断开 SSH 并重新连接，即可看到效果。"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 内部函数: 恢复默认 (封装清理逻辑)
# ------------------------------------------------------------------------------
_restore_default_ps1() {
    print_step "正在清理自定义终端配置..."
    
    local bashrc="$HOME/.bashrc"
    local profile="$HOME/.profile"
    local bash_profile="$HOME/.bash_profile"
    
    # 清理所有可能涉及的文件
    _clean_ps1_config_internal "$bashrc"
    _clean_ps1_config_internal "$profile"
    _clean_ps1_config_internal "$bash_profile"
    
    print_success "已移除所有自定义美化配置。"
    print_echo "${YELLOW}提示：${NC}请断开 SSH 并重新连接，提示符将恢复系统默认。"
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 辅助: 实际执行 sed 删除的底层函数
# ------------------------------------------------------------------------------
_clean_ps1_config_internal() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # 删掉 VpsScriptKit 的标记行
        sed -i '/# VpsScriptKit-Prompt/d' "$file" 2>/dev/null
        # 删掉旧脚本可能留下的残留 (兼容旧版)
        sed -i '/^PS1=/d' "$file" 2>/dev/null
    fi
}

# ------------------------------------------------------------------------------
# 菜单: 命令行美化工具
# ------------------------------------------------------------------------------
terminal_tuning_menu() {
    while true; do
        print_clear
        print_box_header "${ICON_GEAR}$(print_spaces 1)命令行终端美化 (Terminal Beautify)"
        print_line
        
        print_echo "请选择你喜欢的提示符风格 (实际颜色预览):"
        print_line

        # 定义颜色变量
        local R="\033[1;31m" G="\033[1;32m" Y="\033[1;33m" B="\033[1;34m" 
        local P="\033[1;35m" C="\033[1;36m" W="\033[1;37m" N="\033[0m"

        # 选项 1-7
        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "$(echo -e "${G}root ${B}localhost ${R}~ ${N}#")"
        print_menu_item -r 2 -p 0 -i 2 -s 2 -m "$(echo -e "${P}root ${C}localhost ${Y}~ ${N}#")"
        print_menu_item -r 3 -p 0 -i 3 -s 2 -m "$(echo -e "${R}root ${G}localhost ${B}~ ${N}#")"
        print_menu_item -r 4 -p 0 -i 4 -s 2 -m "$(echo -e "${C}root ${Y}localhost ${W}~ ${N}#")"
        print_menu_item -r 5 -p 0 -i 5 -s 2 -m "$(echo -e "${W}root ${R}localhost ${G}~ ${N}#")"
        print_menu_item -r 6 -p 0 -i 6 -s 2 -m "$(echo -e "${Y}root ${B}localhost ${P}~ ${N}#")"
        
        print_menu_item -r 9 -p 0 -i 99 -m "恢复系统默认"
        
        print_menu_item_done
        print_menu_go_level

        local choice
        choice=$(read_choice)

        case "$choice" in
            1) # 绿户 蓝机 红路
                _set_ps1 '\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \[\e[1;31m\]\w\[\e[0m\] \$ ' ;;
            2) # 紫户 青机 黄路
                _set_ps1 '\[\e[1;35m\]\u\[\e[0m\]@\[\e[1;36m\]\h\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] \$ ' ;;
            3) # 红户 绿机 蓝路
                _set_ps1 '\[\e[1;31m\]\u\[\e[0m\]@\[\e[1;32m\]\h\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\] \$ ' ;;
            4) # 青户 黄机 白路
                _set_ps1 '\[\e[1;36m\]\u\[\e[0m\]@\[\e[1;33m\]\h\[\e[0m\] \[\e[1;37m\]\w\[\e[0m\] \$ ' ;;
            5) # 白户 红机 绿路
                _set_ps1 '\[\e[1;37m\]\u\[\e[0m\]@\[\e[1;31m\]\h\[\e[0m\] \[\e[1;32m\]\w\[\e[0m\] \$ ' ;;
            6) # 黄户 蓝机 紫路
                _set_ps1 '\[\e[1;33m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \[\e[1;35m\]\w\[\e[0m\] \$ ' ;;
            99) # 恢复默认
                _restore_default_ps1 ;;
            0) return ;;
            *) print_error "无效选项"; sleep 1 ;;
        esac
    done
}