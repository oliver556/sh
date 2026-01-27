#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 一条龙系统调优
#
# @文件路径: modules/system/tuning/system_tune.sh
# @功能描述: 
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-16
# ==============================================================================

system_tune() {
    print_clear

    print_box_info -m "一条龙调优"

    print_step "将对以下内容进行操作与优化"
    print_echo "1.  优化系统更新源，更新系统到最新"
    print_echo "2.  清理系统垃圾文件"
    print_echo "3.  设置虚拟内存${BOLD_YELLOW} 1G ${NC}"
    print_echo "4.  设置 SSH 端口号为${BOLD_YELLOW} 5566 ${NC}"
    print_echo "5.  开放所有端口"
    print_echo "6.  开启${BOLD_YELLOW} BBR ${NC}加速"
    print_echo "7.  设置时区到${BOLD_YELLOW}上海${NC}"
    print_echo "8.  自动优化 DNS 地址${BOLD_YELLOW}海外: 1.1.1.1 8.8.8.8  国内: 223.5.5.5 ${NC}"
    print_echo "9.  设置网络为${BOLD_YELLOW} IPv4 优先${NC}"
    print_echo "10. 安装基础工具${BOLD_YELLOW} docker wget sudo tar unzip socat btop nano vim${NC}"

    if ! read_confirm; then
        return 1
    fi

    print_clear

    print_box_info -s start -m "一条龙调优..."

    # do something
    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/system/clean.sh"
    run_step -S 2 -m "1.  更新系统到最新" -- guard_system_clean

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/system/update.sh"
    run_step -S 2 -m "2.  清理系统垃圾文件" -- guard_system_update

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/memory/swap.sh"
    run_step -S 2 -m "3.  设置虚拟内存 ${BOLD_YELLOW} 1G ${NC}" -- swap_create 1024

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/network/change_ssh_port.sh"
    run_step -S 2 -m "4.  设置 SSH 端口号为${BOLD_YELLOW} 5566 ${NC}" -- set_ssh_port 5566

    # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/"
    # run_step -S 2 -m "5.  开放所有端口" 函数名
    
    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/kernel/kernel_manager.sh"
    run_step -S 2 -m "6.  开启${BOLD_YELLOW} BBR ${BOLD_GREEN}加速" -- enable_bbrv3_smart
    # enable_bbrv3_smart

    # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/"
    # run_step -S 2 -m "7.  设置时区到${BOLD_YELLOW}上海${NC}" -- 函数名
    
    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/network/change_dns.sh"
    run_step -S 2 -m "8.  自动优化${BOLD_YELLOW} DNS ${BOLD_GREEN}地址" -- modify_dns_task -d "global"

    # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/"
    # run_step -S 2 -m "9.  设置网络为${BOLD_YELLOW} IPv4 优先${NC}" -- 函数名

    # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/"
    # run_step -S 2 -m "10.  安装基础工具${BOLD_YELLOW} docker wget sudo tar unzip socat btop nano vim${NC}" -- 函数名

    print_box_success -s finish -m "一条龙调优"

    print_wait_enter
}