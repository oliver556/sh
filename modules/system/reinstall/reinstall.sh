#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 重装系统逻辑
# @名称:         /modules/system/reinstall/reinstall.sh
# @职责:
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-07
# @修改日期:     2025-01-07
#
# @许可证:       MIT
# ============================================================

# ------------------------------
# 函数: reinstall_finish_reboot
# 描述: 重装指令发送成功后的倒计时与重启逻辑
# ------------------------------
reinstall_finish_reboot() {
    local delay="${REBOOT_DELAY:-3}"
    
    ui blank
    ui line
    ui echo "${LIGHT_GREEN}✅ 重装指令发送成功！${RESET}"
    ui echo "${LIGHT_CYAN}系统将在 ${delay} 秒后自动重启并开始 DD 重装...${RESET}"
    ui echo "${BOLD_YELLOW}请等待约 ${INSTALL_ESTIMATE_TIME:-15} 分钟，期间请勿手动干预服务器。${RESET}"
    ui line

    # 使用数值循环执行倒计时
    for ((i=delay; i>0; i--)); do
        ui echo "${LIGHT_CYAN}${i}...${RESET}"
        sleep 1
    done

    ui echo "${BOLD_YELLOW}🔄 正在执行系统重启...${RESET}"
    
    # 同步磁盘数据并重启
    sync
    reboot
    
    # 彻底结束进程
    exit 0
}

# ------------------------------
# 名称: Leitbogioro 脚本
# @描述: 本函数用于安装 Leitbogioro 脚本
# @参数: $1: string - 脚本执行后缀补充 (e.g., "debian 12")
#
# @GitHub 地址：https://github.com/leitbogioro/Tools
# @示例: reinstall_Leitbogioro "debian 12"
# ------------------------------
reinstall_Leitbogioro() {
    local system_param="$1"
    wget --no-check-certificate -qO InstallNET.sh "${GH_PROXY}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh
    bash InstallNET.sh -"${system_param}"
}

# ------------------------------
# 名称: Bin456789 脚本
# @描述: 本函数用于安装 Bin456789 脚本
# @参数: $1: string - 脚本执行后缀补充 (e.g., "debian 12")
#
# @GitHub 地址：https://github.com/bin456789/reinstall
# @示例: reinstall_bin456789 "debian 12"
# ------------------------------
reinstall_Bin456789() {
    local system_param="$1"
    curl -O "${GH_PROXY}"raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    bash reinstall.sh "${system_param}"
}

# ------------------------------
# @名称: Leitbogioro 脚本安装逻辑 ①
# @描述: 本函数用于安装 Leitbogioro 脚本。
#
# @参数 $1: 系统版本全名 (e.g., "Debian 12")
# @参数 $2: 脚本执行后缀补充 (e.g., "debian 12")
#
# @示例: run_mollylau_install "Debian 12" "debian 12"
# ------------------------------
run_mollylau_install() {
    local system_version_name="$1"
    local system_param="$2"

    ui echo "${BOLD_LIGHT_WHITE}🔄 正在检查系统是否安装有必要环境..."

    # 确保 wget 环境就绪
    ensure_wget || exit 1

    sleep 1

    ui echo "正在准备: ${BOLD_LIGHT_CYAN}[Leitbogioro] DD 脚本...${BOLD_LIGHT_WHITE}"
    ui echo "目标系统: ${BOLD_LIGHT_CYAN}${system_version_name}${BOLD_LIGHT_WHITE}" 

    ui line

    sleep 1
    reinstall_Leitbogioro "${system_param}"
    reinstall_finish_reboot
}

# ------------------------------
# @名称: Bin456789 脚本安装逻辑 ②
# @描述: 本函数用于安装 Bin456789 脚本。
#
# @参数 $1: 系统版本全名 (e.g., "Debian 12")
# @参数 $2: 脚本执行后缀补充 (e.g., "debian 12")
#
# @示例: run_bin456789_install "Debian 12" "debian 12"
# ------------------------------
run_bin456789_install() {
    local system_version_name="$1"
    local system_param="$2"

    ui echo "正在准备: ${BOLD_LIGHT_CYAN}[Bin456789] DD 脚本...${BOLD_LIGHT_WHITE}"
    ui echo "目标系统: ${BOLD_LIGHT_CYAN}${system_version_name}${BOLD_LIGHT_WHITE}" 

    ui line

    sleep 1

    reinstall_Bin456789 "${system_param}"
    sleep 1
    reinstall_finish_reboot
}

# ------------------------------
# 重装信息确认
# @描述: 此函数负责与用户交互，并在确认后调用指定的安装函数。
#
# @参数: $1: string - 系统版本全名 (e.g., "Debian 12")
# @参数: $2: 初始用户名
# @参数: $3: 初始密码
# @参数: $4: 初始端口
# @参数: $5: 需要调用的安装函数名 (e.g., "run_mollylau_install")
# @参数: $6: 脚本执行后缀补充 (e.g., "debian 12")
#
# @返回: 0 (成功/继续), 1 (取消)
# ------------------------------
reinstall_info_config() {
    local name="$1"
    local user pass port func param

    # --- 核心优化：配置查找表 ---
    case "$name" in
        "Debian 13"|"CentOS 10"|"CentOS 9")
            user="root"; pass="123@@@"; port="22"; func="run_bin456789_install"
            [[ "$name" == "Debian 13" ]] && param="debian 13"
            [[ "$name" == "CentOS 10" ]] && param="centos 10"
            [[ "$name" == "CentOS 9" ]] && param="centos 9"
            ;;
        "Debian 12"|"Debian 11"|"Debian 10"|"Ubuntu 24.04"|"Ubuntu 22.04"|"Ubuntu 20.04"|"Ubuntu 18.04")
            user="root"; pass="LeitboGi0ro"; port="22"; func="run_mollylau_install"
            param=$(echo "$name" | tr '[:upper:]' '[:lower:]')
            ;;
        "Windows 11"|"Windows 10"|"Windows 7")
            user="Administrator"; pass="Teddysun.com"; port="3389"; func="run_mollylau_install"
            param="-windows ${name#Windows } -lang \"cn\""
            ;;
        "Windows Server 2025"|"Windows Server 2022"|"Windows Server 2019")
            user="Administrator"; pass="Teddysun.com"; port="3389"; func="run_mollylau_install"
            local ver_num=$(echo "$name" | awk '{print $NF}')
            param="-windows ${ver_num} -lang \"cn\""
            ;;
        "Alpine Linux")
            user="root"; pass="LeitboGi0ro"; port="22"; func="run_mollylau_install"; param="-alpine"
            ;;
        *)
            ui_error "未找到该系统的重装预设配置: $name"
            return 1
            ;;
    esac

    ui echo "${LIGHT_CYAN}请最后确认您的安装选项:${BOLD_LIGHT_WHITE}"
    ui line
    ui echo "${LIGHT_CYAN}- 系统版本:${BOLD_LIGHT_WHITE} ${BOLD_RED}${name}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始用户:${BOLD_LIGHT_WHITE} ${YELLOW}${user}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始密码:${BOLD_LIGHT_WHITE} ${YELLOW}${pass}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始端口:${BOLD_LIGHT_WHITE} ${YELLOW}${port}${BOLD_LIGHT_WHITE}"
    ui line

    ui blank

    ui echo "${BOLD_RED}警告: 这将清除目标服务器上的所有数据！${BOLD_LIGHT_WHITE}"
    ui echo "${BOLD_RED}请务必记录好上述密码，以免重装后失联。${BOLD_LIGHT_WHITE}"

    if ! ui_confirm "确认开始重装系统？"; then
        return 1
    fi

    ui blank

    ui_info "${BOLD_LIGHT_GREEN}确认完毕，准备开始 DD！${BOLD_LIGHT_WHITE}"

    ui line
    ui echo "${BOLD_LIGHT_CYAN}马上开始重装系统${BOLD_LIGHT_WHITE}"
    ui line

    sleep 2

    # 动态调用传入的安装函数名，并将系统名称作为参数传递给它
    "${func}" "${name}" "${param}"

    return
}

# ------------------------------
# 重装系统逻辑
# ------------------------------
reinstall_logic_main() {
    ui clear
    reinstall_info_config "$1"
    return $?
}