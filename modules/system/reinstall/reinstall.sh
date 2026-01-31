#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 重装系统逻辑
#
# @文件路径: modules/system/reinstall/reinstall.sh
# @功能描述: 重装系统逻辑
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-07
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: reinstall_finish_reboot
# 功能:   重装指令发送成功后的倒计时与重启逻辑
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   reinstall_finish_reboot
# ------------------------------------------------------------------------------
reinstall_finish_reboot() {
    local delay="${REBOOT_DELAY:-3}"
    
    print_blank
    print_line
    print_success "重装预处理已完成！"
    print_info "系统将在 ${delay} 秒后自动重启并开始 DD..."
    print_warn "提示: 重启后 SSH 将断开，请等待 15-30 分钟，期间请勿手动干预服务器。"

    print_line

    # 使用数值循环执行倒计时
    for ((i=delay; i>0; i--)); do
        print_echo "${BOLD_CYAN}${i}...${NC}"
        sleep 1
    done

    print_step -m "开始 DD，终端即将断开..."
    
    # 同步磁盘数据并重启
    sync
    reboot
    
    # 彻底结束进程
    exit 0
}

# ------------------------------------------------------------------------------
# 函数名: reinstall_Leitbogioro
# 功能:   安装 Leitbogioro 脚本 [Leitbogioro 脚本]
# @项目地址: https://github.com/leitbogioro/Tools
# 
# 参数:
#   $1 (string): 脚本执行后缀补充 (e.g., "debian 12") (必填)
# 
# 返回值:
#   无
# 
# 示例:
#   reinstall_Leitbogioro "debian 12"
# ------------------------------------------------------------------------------
reinstall_Leitbogioro() {
    local system_param="$1"
    local url="${GH_PROXY}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh"
    
    print_step "正在下载 [Leitbogioro] DD 脚本..."
    wget --no-check-certificate -qO InstallNET.sh "$url" || curl -sLO "$url"
    chmod a+x InstallNET.sh
    
    print_step "正在启动 [Leitbogioro] DD 脚本，请稍后..."
    bash InstallNET.sh ${system_param}
    
    # 返回 InstallNET.sh 的执行状态码
    return $?
}

# ------------------------------------------------------------------------------
# 函数名: reinstall_Bin456789
# 功能:   安装 Bin456789 脚本 [Bin456789 脚本]
# @项目地址: https://github.com/bin456789/reinstall
# 
# 参数:
#   $1 (string): 脚本执行后缀补充 (e.g., "debian 12") (必填)
# 
# 返回值:
#   无
# 
# 示例:
#   reinstall_Bin456789 "debian 12"
# ------------------------------------------------------------------------------
reinstall_Bin456789() {
    local system_param="$1"
    local url="${GH_PROXY}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    
    print_step "正在下载 [Bin456789] DD 脚本..."
    # 采用作者文档推荐的多路下载兼容方式，且由于使用 bash 运行，无需 chmod
    curl -sLO "$url" || wget -qO reinstall.sh "$url"

    print_step "正在启动 [Bin456789] DD 脚本，请稍后..."

    bash reinstall.sh ${system_param}

    return $?
}

# ------------------------------------------------------------------------------
# 函数名: run_mollylau_install
# 功能:    Leitbogioro 脚本安装逻辑 ① [安装 Leitbogioro 脚本。]
# 
# 参数:
#   $1 (string): 系统版本全名 (e.g., "Debian 12") (必填)
#   $2 (string): 脚本执行后缀补充 (e.g., "debian 12") (必填)
# 
# 返回值:
#   无
# 
# 示例:

#   run_mollylau_install "Debian 12" "debian 12"
# ------------------------------------------------------------------------------
run_mollylau_install() {
    local system_version_name="$1"
    local system_param="$2"
    local log_file="/tmp/dd_install_leitbogioro.log" # 定义临时日志文件

    print_step "正在检查系统是否安装有必要环境..."
    # 检查必要环境
    ensure_cmd "update-ca-certificates" "ca-certificates" || return 1
    ensure_cmd wget || return 1
    ensure_cmd "xz" "xz-utils" || return 1

    print_step "正在准备: [Leitbogioro] DD 脚本..."
    print_step "目标系统: ${system_version_name}" 

    # 开启 pipefail: 确保管道中的输出能被捕获
    set -o pipefail

    # 执行安装脚本，使用 tee 同时输出到屏幕和日志文件
    # 2>&1 确保错误输出也能被 grep 抓到
    reinstall_Leitbogioro "${system_param}" 2>&1 | tee "$log_file"

    # 获取执行结果
    local ret_code=$?

    # 关闭 pipefail
    set +o pipefail

    # 智能判断
    # 条件 A: 退出码为 0 (标准成功)
    # 条件 B: 日志里包含 "Input 'reboot'"
    if [[ $ret_code -eq 0 ]] || grep -aE "Input.*reboot" "$log_file" >/dev/null 2>&1; then
        print_blank
        print_success "检测到 DD 脚本执行完毕，自动接管并重启"
        reinstall_finish_reboot
    else
        # 失败
        print_error "DD 脚本执行失败 (错误码: $ret_code)！"
        print_error "未在日志中检测到成功标识，系统未重启。"
        print_warn "你可以查看日志文件诊断问题: cat $log_file"
        
        read -r -p "按回车键返回主菜单..."
        return 1
    fi
    # ==============================================
}

# ------------------------------------------------------------------------------
# 函数名: run_bin456789_install
# 功能:    Bin456789 脚本安装逻辑 ① [安装 Bin456789 脚本。]
# 
# 参数:
#   $1 (string): 系统版本全名 (e.g., "Debian 12") (必填)
#   $2 (string): 脚本执行后缀补充 (e.g., "debian 12") (必填)
# 
# 返回值:
#   无
# 
# 示例:
#   run_bin456789_install "Debian 12" "debian 12"
# ------------------------------------------------------------------------------
run_bin456789_install() {
    local system_version_name="$1"
    local system_param="$2"
    local log_file="/tmp/dd_install_bin.log" # 定义临时日志文件

    print_step "正在检查系统是否安装有必要环境..."
    # 检查必要环境
    ensure_cmd "update-ca-certificates" "ca-certificates" || return 1
    ensure_cmd curl || return 1
    ensure_cmd "xz" "xz-utils" || return 1

    print_step "正在准备: [Bin456789] DD 脚本..."
    print_step "目标系统: ${system_version_name}"

    # 执行安装脚本
    set -o pipefail
    reinstall_Bin456789 "${system_param}" 2>&1 | tee "$log_file"
    # 获取执行结果
    local ret_code=$?
    set +o pipefail

    # 智能判断
    if [[ $ret_code -eq 0 ]]; then
        print_blank
        print_success "检测到 DD 脚本执行完毕，自动接管并重启"
        reinstall_finish_reboot
    else
        print_error "DD 脚本执行失败 (错误码: $ret_code)！"
        print_warn "请检查上方报错信息。"
        read  -r -p "按回车键返回主菜单..."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 函数名: reinstall_info_config
# 功能:   重装信息确认，与用户交互，并在确认后调用指定的安装函数。
# 
# 参数:
#   $1 (string): 系统版本全名 (e.g., "Debian 12") (必填)
#   $2 (string): 初始用户名 (必填)
#   $3 (string): 初始密码 (必填)
#   $4 (string): 初始端口 (必填)
#   $5 (string): 需要调用的安装函数名 (e.g., "run_mollylau_install") (必填)
#   $6 (string): 脚本执行后缀补充 (e.g., "debian 12") (必填)
# 
# 返回值:
#   0 - 成功 / 继续
#   1 - 取消
# 
# 示例:
#   reinstall_info_config "Debian 12" "debian 12"
# ------------------------------------------------------------------------------
reinstall_info_config() {
    local name="$1"
    local user pass port func param

    case "$name" in
        "Debian 13"|"Debian 10"|"Ubuntu 18.04"|"CentOS 10"|"CentOS 9")
            user="root"; pass="123@@@"; port="22"; func="run_bin456789_install"
            local os_low
            os_low=$(echo "$name" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
            local ver_num
            ver_num=$(echo "$name" | awk '{print $2}')
            param="${os_low} ${ver_num} --password ${pass} --ssh-port ${port}"
            ;;
        "Debian 12"|"Debian 11"|"Ubuntu 24.04"|"Ubuntu 22.04"|"Ubuntu 20.04")
            user="root"; pass="LeitboGi0ro"; port="22"; func="run_mollylau_install"
            local os_low
            os_low=$(echo "$name" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
            local ver_num
            ver_num=$(echo "$name" | awk '{print $2}')
            param="-${os_low} ${ver_num} -pwd ${pass} -port ${port}"
            ;;
        "Windows"*)
            user="Administrator"; pass="Teddysun.com"; port="3389"; func="run_mollylau_install"
            if [[ "$name" == *"Server"* ]]; then
                local win_ver
                win_ver=$(echo "$name" | awk '{print $NF}')
                param="-windows ${win_ver} -lang cn -pwd ${pass}"
            else
                param="-windows ${name#Windows } -lang cn -pwd ${pass}"
            fi
            ;;
        "Alpine Linux")
            user="root"; pass="LeitboGi0ro"; port="22"; func="run_mollylau_install";
            param="-alpine -pwd ${pass} -port ${port}"
            ;;
        *)
            print_error "未找到该系统的重装预设配置: $name"
            return 1
            ;;
    esac

    print_box_info "请最后确认您的安装选项:"
    print_line
    print_tip "系统版本: ${BOLD_RED}${name}${NC}"
    print_tip "初始用户: ${user}${NC}"
    print_tip "初始密码: ${pass}${NC}"
    print_tip "初始端口: ${port}${NC}"
    print_line

    print_warn "警告: 这将清除目标服务器上的所有数据！"
    print_warn "请务必记录好上述密码，以免重装后失联。"

    if ! read_confirm; then
        return 1
    fi

    print_box_info -C "$BOLD_GREEN" -m "确认完毕，准备开始 DD！"

    # 动态调用传入的安装函数名，并将系统名称作为参数传递给它
    # "${func}" "${name}" "${param}"
    if [[ "$func" == *"run_bin456789_install"* ]]; then
        run_bin456789_install "${name}" "${param}"
    elif [[ "$func" == *"run_mollylau_install"* ]]; then
        run_mollylau_install "${name}" "${param}"
    else
        print_error "严重错误：未知的安装函数指令 [$func]"
        return 1
    fi

    return $?
}

# ------------------------------------------------------------------------------
# 函数名: reinstall_logic_main
# 功能:   重装系统逻辑
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   reinstall_logic_main
# ------------------------------------------------------------------------------
reinstall_logic_main() {
    print_clear
    reinstall_info_config "$1"
    return $?
}