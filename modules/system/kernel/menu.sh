#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - 内核管理菜单 - 入口
#
# @文件路径: modules/system/kernel/menu.sh
# @功能描述: 内核管理菜单 - 子菜单
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-26
# ==============================================================================

# 引入逻辑库
# shellcheck disable=SC1091
source "${BASE_DIR}/modules/system/kernel/kernel_manager.sh"

# ------------------------------------------------------------------------------
# 函数名: kernel_menu
# 功能:   内核管理菜单 - 菜单
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   kernel_menu
# ------------------------------------------------------------------------------
kernel_menu() {
    while true; do
        print_clear
        print_box_header "${ICON_GEAR}$(print_spaces 1)内核与 BBR3 管理 (Kernel Manager)"
        print_line
        
        # 状态栏 (自动判断 BBR 状态)
        local k_ver
        k_ver=$(uname -r)
        local bbr_status
        bbr_status=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
        
        # 内核显示逻辑
        local k_display="${GRAY}系统默认 ($k_ver)${NC}"
        if [[ "$k_ver" == *"xanmod"* ]]; then
            k_display="${GREEN}XanMod 高性能内核 ($k_ver)${NC}"
        fi
        
        # BBR 显示逻辑
        local bbr_display="${GRAY}未开启${NC}"
        if [[ "$bbr_status" == "bbr" ]]; then
            bbr_display="${GREEN}已开启 (BBR)${NC}"
        fi

        print_echo "当前内核: ${k_display}"
        print_echo "BBR 状态: ${bbr_display}"
        print_line

        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "开启 BBRv3 加速" -I "star" -S 2
        print_menu_item -r 2 -p 0 -i 2 -s 2 -m "关闭 BBRv3 还原"
        print_menu_item_done

        print_line
        print_menu_item -r 3 -p 0 -i 3 -s 2 -m "Teddysun 脚本 (秋水逸冰)"
        print_menu_item -r 4 -p 0 -i 4 -s 2 -m "ylx2016 脚本 (TCPX)"
        print_menu_item_done
        
        # print_line
        # print_menu_item -r 9 -p 0 -i 9 -s 2 -m "高级内核管理 (手动安装/卸载)"
        # print_menu_item_done
        
        print_menu_go_level

        local choice
        choice=$(read_choice)

        case "$choice" in
            1) if enable_bbrv3_smart; then print_wait_enter; fi ;;
            2) disable_bbrv3_smart ;;
            3)
                # Teddysun (秋水逸冰) - 经典，兼容性好，支持 BBRPlus
                wget -N --no-check-certificate "https://github.000060000.xyz/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
                print_wait_enter
                ;;
            4)
                # ylx2016 (TCPX) - 支持很多暴力内核
                wget --no-check-certificate -O tcpx.sh "https://github.000060000.xyz/tcpx.sh" && chmod +x tcpx.sh && ./tcpx.sh
                print_wait_enter
                ;;
            0) return ;;
            *) print_error "无效选项"; sleep 1 ;;
        esac
    done
}