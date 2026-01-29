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
_draw_mirror_status() {
    local source_file=""
    local current_mirror="${GRAY}未知 / 检测失败${NC}"
    local check_content=""

    # 1. 确定配置文件路径
    if [[ -f "/etc/apt/sources.list" ]]; then
        source_file="/etc/apt/sources.list"
        # 读取非注释的第一行有效配置
        check_content=$(grep -vE "^#|^$" "$source_file" | head -n 5)
    elif [[ -d "/etc/yum.repos.d" ]]; then
        # CentOS/RedHat 扫描目录下的 .repo 文件
        check_content=$(grep -r "baseurl" /etc/yum.repos.d 2>/dev/null | head -n 5)
    elif [[ -f "/etc/apk/repositories" ]]; then
        source_file="/etc/apk/repositories"
        check_content=$(cat "$source_file")
    fi

    # 2. 匹配关键字 (优先级：内网/厂商源 > 官方源)
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
            # 提取域名作为兜底显示
            local domain
            domain=$(echo "$check_content" | grep -oE 'https?://[^/]+' | head -n 1 | cut -d/ -f3)
            if [[ -n "$domain" ]]; then
                current_mirror="${WHITE}${domain}${NC}"
            fi
        fi
    fi

    # 3. 绘制状态栏
    # -w 12 是标签宽度，根据你的 "中国大陆 (默认)" 长度视觉调整的
    print_status_item -l "当前系统源:" -v "${current_mirror}" -w 14
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
            print_echo "${GRAY}正在检测网络连通性...${NC}"
            
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
# 函数名: mirror_menu
# 功能:   换源中心主菜单
# ------------------------------------------------------------------------------
mirror_menu() {
    while true; do
        print_clear
        print_box_header "系统更新源配置 (LinuxMirrors)"
        print_box_header_tip "基于 LinuxMirrors 开源项目"
        print_line
        _draw_mirror_status
        print_line
        print_menu_item -p 0 -i 1 -s 2 -m "中国大陆 (默认)"
        print_menu_item -p 0 -i 2 -s 2 -m "中国大陆 (教育网)"
        print_menu_item -p 0 -i 3 -s 2 -m "海外地区 (推荐)"
        print_line
        print_menu_item -p 0 -i 4 -s 2 -m "智能切换更新源"

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1) run_linuxmirrors "cn" ;;
            2) run_linuxmirrors "edu" ;;
            3) run_linuxmirrors "abroad" ;;
            4) run_linuxmirrors "smart" ;;
            0) return ;;
            *) print_error -m "无效选项" ;;
        esac
    done
}