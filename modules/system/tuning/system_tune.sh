#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 一条龙系统调优
#
# @文件路径: modules/system/tuning/system_tune.sh
# @功能描述: 智能判断是否需要重启，实现无缝或断点续传的系统调优
#
# @作者: Jamison
# @版本: 1.2.0 (UX 优化版)
# @创建日期: 2026-01-16
# ==============================================================================

# ------------------------------------------------------------------------------
# 内部函数: 步骤 6-10 的具体执行逻辑
# 说明: 无论是重启回来的，还是直接顺着跑的，最终都执行这段代码
# ------------------------------------------------------------------------------
_system_tune_process_steps_6_to_10() {
    # 步骤 6: 开启 BBR
    # 此时内核肯定已经满足要求了 (要么是本来就满足，要么是刚重启完)
    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/kernel/kernel_manager.sh"
    run_step -S 2 -m "6.  开启${BOLD_YELLOW} BBR ${BOLD_GREEN}加速" -- enable_bbrv3_smart "true"

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/timezone/timezone.sh"
    run_step -S 2 -m "7.  设置时区到${BOLD_YELLOW}上海${NC}" -- set_timezone "Asia/Shanghai"
    
    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/network/change_dns.sh"
    run_step -S 2 -m "8.  自动优化${BOLD_YELLOW} DNS ${BOLD_GREEN}地址" -- modify_dns_task -d "global"

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/network/ipv_priority.sh"
    run_step -S 2 -m "9.  设置网络为${BOLD_YELLOW} IPv4 优先${NC}" -- set_ipv4_prefer

    # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/"
    # run_step -S 2 -m "10.  安装基础工具..." -- 函数名
    
    # # shellcheck disable=SC1091
    # source "${BASE_DIR}/modules/system/ssh/ssh_config.sh"
    # run_step -S 2 -m "4.  设置 SSH 端口号为${BOLD_YELLOW} 5566 ${NC}" -- ssh_set_port 5566

    print_box_success -s finish -m "一条龙调优全部完成！"
    print_wait_enter
}

# ==============================================================================
# 入口 2: 重启后的接盘入口 (仅在触发了重启时才会被调用)
# ==============================================================================
system_tune_resume() {
    # 因为是重启回来的，所以需要清屏并打印一个“欢迎回来”的 Header
    print_clear
    print_box_info -s start -m "继续执行一条龙调优 (阶段 2/2)..."
    
    # 执行后半段逻辑
    _system_tune_process_steps_6_to_10
}

# ==============================================================================
# 入口 1: 主菜单入口
# ==============================================================================
system_tune() {
    print_clear

    print_box_info -m "一条龙调优"

    print_step "将对以下内容进行操作与优化"
    print_echo "1.  优化系统更新源，更新系统到最新"
    print_echo "2.  清理系统垃圾文件"
    print_echo "3.  设置虚拟内存${BOLD_YELLOW} 1G ${NC}"
    # print_echo "4.  设置 SSH 端口号为${BOLD_YELLOW} 5566 ${NC} (最后执行)"
    # print_echo "5.  开放所有端口"
    print_echo "6.  开启${BOLD_YELLOW} BBR ${NC}加速"
    print_echo "7.  设置时区到${BOLD_YELLOW}上海${NC}"
    print_echo "8.  自动优化 DNS 地址"
    print_echo "9.  设置网络为${BOLD_YELLOW} IPv4 优先${NC}"
    # print_echo "10. 安装基础工具${BOLD_YELLOW} docker wget sudo tar unzip socat btop nano vim${NC}"

    if ! read_confirm; then
        return 1
    fi

    print_clear

    print_box_info -s start -m "一条龙调优..."

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/system/clean.sh"
    run_step -S 2 -m "1.  更新系统到最新" -- guard_system_clean

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/system/update.sh"
    run_step -S 2 -m "2.  清理系统垃圾文件" -- guard_system_update

    # shellcheck disable=SC1091
    source "${BASE_DIR}/modules/system/memory/swap.sh"
    run_step -S 2 -m "3.  设置虚拟内存 ${BOLD_YELLOW} 1G ${NC}" -- swap_create 1024

    # 注意：步骤 4 (端口) 已经移到最后执行，这里跳过
    
    # shellcheck disable=SC1091
    # run_step -S 2 -m "5.  开放所有端口" ...

    # === 内核检查与分流 ===
    
    source "${BASE_DIR}/modules/system/kernel/kernel_manager.sh"
    
    local current_kernel
    current_kernel=$(uname -r)
    local arch
    arch=$(uname -m)

    # 判断条件：是 x86 且 不是 XanMod
    if [[ "$arch" == "x86_64" ]] && [[ "$current_kernel" != *"xanmod"* ]]; then
        print_box_info -m "内核检查"
        print_warn "检测到需要安装 XanMod 内核以支持 BBRv3。"
        print_tip "系统将在安装后自动重启，并自动继续后续步骤。"
        
        sleep 2
        
        # 【分支 A】需要重启
        # 传入回调函数名，install 函数会负责埋点和重启
        _install_xanmod_action "system_tune_resume"
        
        # 脚本在这里终止（因为会 reboot）
        return
    else
        # 【分支 B】不需要重启 (Debian 11/12, Ubuntu 22+, 或已安装 XanMod)
        # 直接继续执行后半段，不清屏，不中断，体验如丝般顺滑
        _system_tune_process_steps_6_to_10
    fi
}