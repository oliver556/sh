#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统换源模块
#
# @文件路径: modules/system/mirror.sh
# @功能描述: 集成 LinuxMirrors 进行系统软件源的智能切换与配置
#
# @作者: Jamison
# @版本: 0.1.0
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: _draw_mirror_status
# 功能:   检测并绘制当前系统源状态
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 函数名: _draw_mirror_status
# 功能:   检测并绘制当前系统源状态 + 备份状态
# ------------------------------------------------------------------------------
_draw_mirror_status() {
    local source_file=""
    local current_mirror="${GREY}未知 / 检测失败${NC}"
    local check_content=""
    
    # 备份检测变量
    local bak_file=""
    local bak_status="${GREY}无备份${NC}"

    # 1. 确定配置文件路径 & 备份文件路径
    if [[ -f "/etc/apt/sources.list" ]]; then
        source_file="/etc/apt/sources.list"
        bak_file="/etc/apt/sources.list.vsk.bak"
        check_content=$(grep -vE "^#|^$" "$source_file" | head -n 5)
    elif [[ -d "/etc/yum.repos.d" ]]; then
        # CentOS/RedHat
        check_content=$(grep -r "baseurl" /etc/yum.repos.d 2>/dev/null | head -n 5)
        bak_file="/etc/yum.repos.d.vsk.bak.tar.gz"
    elif [[ -f "/etc/apk/repositories" ]]; then
        source_file="/etc/apk/repositories"
        bak_file="/etc/apk/repositories.vsk.bak"
        check_content=$(cat "$source_file")
    fi

    # 2. 匹配当前源关键字
    if [[ -n "$check_content" ]]; then
        if echo "$check_content" | grep -q "aliyun.com"; then
            current_mirror="${GREEN}阿里云 (Aliyun)${NC}"
        elif echo "$check_content" | grep -q "tencent.com"; then
            current_mirror="${GREEN}腾讯云 (Tencent)${NC}"
        elif echo "$check_content" | grep -q "huaweicloud.com"; then
            current_mirror="${GREEN}华为云 (Huawei)${NC}"
        elif echo "$check_content" | grep -q "tsinghua.edu.cn"; then
            current_mirror="${CYAN}清华大学 (TUNA)${NC}"
        elif echo "$check_content" | grep -q "ustc.edu.cn"; then
            current_mirror="${CYAN}中科大 (USTC)${NC}"
        elif echo "$check_content" | grep -q "163.com"; then
            current_mirror="${GREEN}网易 (163)${NC}"
        elif echo "$check_content" | grep -qE "volces.com|volcengine"; then
            current_mirror="${GREEN}火山引擎 (Volcengine)${NC}"
        elif echo "$check_content" | grep -qE "debian.org|ubuntu.com|centos.org|fedoraproject.org|alpinelinux.org"; then
            current_mirror="${YELLOW}官方源 (Official)${NC}"
        else
            local domain
            domain=$(echo "$check_content" | grep -oE 'https?://[^/]+' | head -n 1 | cut -d/ -f3)
            if [[ -n "$domain" ]]; then
                current_mirror="${WHITE}${domain}${NC}"
            fi
        fi
    fi

    # 3. 检测备份文件状态
    if [[ -f "$bak_file" ]]; then
        local bak_time
        # 兼容 Linux/Mac 的文件修改时间获取
        if date --version >/dev/null 2>&1; then
            # Linux (GNU date)
            bak_time=$(date -r "$bak_file" "+%Y-%m-%d %H:%M")
        else
            # Mac/BSD
            bak_time=$(date -r "$bak_file" "+%Y-%m-%d %H:%M")
        fi
        bak_status="${GREEN}已备份 (${bak_time})${NC}"
    fi

    # 4. 绘制状态栏 (双行显示)
    print_status_item -l "当前系统源:" -v "${current_mirror}" -w 14 -W 28
    print_status_item -l "配置备份:" -v "${bak_status}" -w 10
    print_status_done
}

# ------------------------------------------------------------------------------
# 函数名: run_linuxmirrors
# 功能:   执行换源脚本
# 参数:   $1 (mode) - cn | edu | abroad | smart
# ------------------------------------------------------------------------------
run_linuxmirrors() {
    local mode="$1"
    local script_url="https://linuxmirrors.cn/main.sh"
    local args=""
    
    print_clear
    print_box_info -m "正在准备 LinuxMirrors 换源环境..." -s start

    case "$mode" in
        cn)
            print_step -m "模式: 中国大陆 (默认)"
            # 默认模式无需额外参数，交互式选择
            ;;
        edu)
            print_step -m "模式: 中国大陆 (教育网)"
            args="--edu"
            ;;
        abroad)
            print_step -m "模式: 海外地区 (官方/全球源)"
            args="--abroad"
            ;;
        smart)
            print_step -m "模式: 智能切换"
            print_echo "${GREY}正在检测网络连通性...${NC}"
            
            local region
            region=$(net_region)
            
            if [[ "$region" == "Global" ]]; then
                log_info "检测到国际互联 (Global)"
                print_step -m "已自动切换至海外模式 (--abroad)"
                args="--abroad"
            else
                log_info "检测到中国大陆 (CN)"
                print_step -m "已自动切换至国内模式 (默认)"
                # 国内模式不加参数，默认就是国内源
            fi
            
            sleep 1
            ;;
    esac

    print_line
    print_info -m "正在拉取脚本: ${script_url}"
    print_info -m "执行参数: ${args:-无}"
    print_line
    
    # 执行 LinuxMirrors
    bash <(curl -sSL "$script_url") $args
    
    # 执行结束后提示
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: backup_source
# 功能:   备份当前系统源配置文件
# ------------------------------------------------------------------------------
backup_source() {
    print_clear
    print_box_info -m "正在备份当前系统源配置..." -s start

    local success=false

    # Debian/Ubuntu
    if [[ -f "/etc/apt/sources.list" ]]; then
        print_step -m "检测到 Apt 源 (Debian/Ubuntu)"
        cp "/etc/apt/sources.list" "/etc/apt/sources.list.vsk.bak"
        # 同时也备份 sources.list.d 目录，防止有残留
        if [[ -d "/etc/apt/sources.list.d" ]]; then
            tar -czf "/etc/apt/sources.list.d.vsk.bak.tar.gz" -C /etc/apt sources.list.d
        fi
        success=true
    
    # CentOS/RedHat/Fedora
    elif [[ -d "/etc/yum.repos.d" ]]; then
        print_step -m "检测到 Yum/Dnf 源 (CentOS/RHEL)"
        # 打包整个目录，最稳妥
        tar -czf "/etc/yum.repos.d.vsk.bak.tar.gz" -C /etc yum.repos.d
        success=true
    
    # Alpine
    elif [[ -f "/etc/apk/repositories" ]]; then
        print_step -m "检测到 Apk 源 (Alpine)"
        cp "/etc/apk/repositories" "/etc/apk/repositories.vsk.bak"
        success=true
    fi

    if [[ "$success" == "true" ]]; then
        print_box_success -m "备份成功！文件后缀已标记为 .vsk.bak"
    else
        print_box_error -m "未找到支持的源配置文件，备份失败。"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: restore_source
# 功能:   还原之前备份的系统源配置
# ------------------------------------------------------------------------------
restore_source() {
    print_clear
    print_box_info -m "正在还原系统源配置..." -s start

    local success=false
    local update_cmd=""

    # Debian/Ubuntu
    if [[ -f "/etc/apt/sources.list.vsk.bak" ]]; then
        print_step -m "发现 Apt 源备份，正在还原..."
        cp -f "/etc/apt/sources.list.vsk.bak" "/etc/apt/sources.list"
        
        # 还原 sources.list.d (如果有)
        if [[ -f "/etc/apt/sources.list.d.vsk.bak.tar.gz" ]]; then
            rm -rf /etc/apt/sources.list.d/*
            tar -xzf "/etc/apt/sources.list.d.vsk.bak.tar.gz" -C /etc/apt
        fi
        
        update_cmd="apt-get update"
        success=true

    # CentOS/RedHat/Fedora
    elif [[ -f "/etc/yum.repos.d.vsk.bak.tar.gz" ]]; then
        print_step -m "发现 Yum/Dnf 源备份，正在还原..."
        # 清空当前目录，防止新旧混用
        rm -rf /etc/yum.repos.d/*
        # 解压还原
        tar -xzf "/etc/yum.repos.d.vsk.bak.tar.gz" -C /etc
        
        if command -v dnf &>/dev/null; then
            update_cmd="dnf makecache"
        else
            update_cmd="yum makecache"
        fi
        success=true

    # Alpine
    elif [[ -f "/etc/apk/repositories.vsk.bak" ]]; then
        print_step -m "发现 Apk 源备份，正在还原..."
        cp -f "/etc/apk/repositories.vsk.bak" "/etc/apk/repositories"
        update_cmd="apk update"
        success=true
    else
        print_box_error -m "未找到 VSK 备份文件 (.vsk.bak)，无法还原。"
        print_wait_enter
        return
    fi

    if [[ "$success" == "true" ]]; then
        print_step -m "配置还原成功，正在刷新缓存..."
        print_line
        # 执行更新命令，让还原生效
        eval "$update_cmd"
        print_line
        print_box_success -m "源配置已恢复到备份状态！"
    fi
    print_wait_enter
}

# ------------------------------------------------------------------------------
# 函数名: mirror_menu
# 功能:   换源中心主菜单
# ------------------------------------------------------------------------------
mirror_menu() {
    while true; do
        print_clear
        print_box_header "切换系统更新源 (LinuxMirrors)"
        print_box_header_tip "基于 LinuxMirrors 开源项目"
        print_line
        _draw_mirror_status
        print_line
        print_menu_item -p 0 -i 1 -s 2 -m "中国大陆 (默认)"
        print_menu_item -p 0 -i 2 -s 2 -m "中国大陆 (教育网)"
        print_menu_item -p 0 -i 3 -s 2 -m "海外地区 (推荐)"
        print_line
        print_menu_item -p 0 -i 4 -s 2 -m "智能切换更新源"

        print_line
        print_menu_item -p 0 -i 5 -s 2 -m "备份当前源配置"
        print_menu_item -p 0 -i 6 -s 2 -m "恢复源配置备份"

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1) run_linuxmirrors "cn" ;;
            2) run_linuxmirrors "edu" ;;
            3) run_linuxmirrors "abroad" ;;
            4) run_linuxmirrors "smart" ;;
            5) backup_source ;;
            6) restore_source ;;
            0) return ;;
            *) print_error -m "无效选项" ;;
        esac
    done
}