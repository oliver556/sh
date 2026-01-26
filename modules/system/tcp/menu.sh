#!/usr/bin/env bash
# ==============================================================================
# VpsScriptKit - TCP 网络调优 - 入口
#
# @文件路径: modules/system/tcp/menu.sh
# @功能描述: TCP 网络调优子菜单
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-26
# ==============================================================================

# 引入逻辑文件
# shellcheck disable=SC1091
source "${BASE_DIR}/modules/system/tcp/tcp_tuning.sh"

# ------------------------------------------------------------------------------
# 内部函数: 检查 BBR 状态
# ------------------------------------------------------------------------------
# _check_bbr_status() {
#     local cc
#     cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
#     if [[ "$cc" == "bbr" ]]; then
#         echo -e "${GREEN}已开启 (bbr)${NC}"
#     else
#         echo -e "${YELLOW}未开启 (当前: ${cc})${NC}"
#     fi
# }

# ------------------------------------------------------------------------------
# 函数名: tcp_tuning_menu
# 功能:   TCP 网络调优模块菜单
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   tcp_tuning_menu
# ------------------------------------------------------------------------------
tcp_tuning_menu() {
    while true; do
    
        print_clear
        print_box_header "${ICON_GEAR}$(print_spaces 1)TCP 网络调优 (TCP Tuning)"
        print_line
        
        # 头部状态栏：简单显示是否已应用脚本优化
        if [[ -f "$SYSCTL_CUSTOM_FILE" ]]; then
            print_echo "优化状态: ${GREEN}已应用 (Custom Profile)${NC}"
        else
            print_echo "优化状态: ${GRAY}系统默认 (Default)${NC}"
        fi

        print_line

        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "TCP 调优"
        print_menu_item -r 2 -p 0 -i 2 -s 2 -m "查看生效参数"
        print_menu_item -r 3 -p 0 -i 3 -s 2 -m "手动备份当前配置"
        print_menu_item -r 4 -p 0 -i 4 -s 2 -m "备份文件列表"
        print_menu_item -r 5 -p 0 -i 5 -s 2 -m "删除备份文件"
        print_menu_item -r 6 -p 0 -i 6 -s 2 -m "${RED}恢复系统默认 (Restore Default)${NC}"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1) apply_performance_tuning ;;
            2) view_tuning_status ;;
            3) manual_backup_config ;;
            4) manage_backups ;;
            5) delete_backup ;;
            6) restore_default_tuning ;;
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