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
    local SYSTEM_PARAM="$1"
    wget --no-check-certificate -qO InstallNET.sh "${GH_PROXY}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh
    bash InstallNET.sh -"${SYSTEM_PARAM}"
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
    local SYSTEM_VERSION_NAME="$1"
    local SYSTEM_PARAM="$2"

    ui echo "${BOLD_LIGHT_WHITE}🔄 正在检查系统是否安装有必要环境..."

    # 确保 wget 环境就绪
    ensure_wget || exit 1

    sleep 1

    ui echo "正在准备: ${BOLD_LIGHT_CYAN}[Leitbogioro] DD 脚本...${BOLD_LIGHT_WHITE}"
    ui echo "目标系统: ${BOLD_LIGHT_CYAN}${SYSTEM_VERSION_NAME}${BOLD_LIGHT_WHITE}" 

    ui line

    sleep 2

    reinstall_Leitbogioro "${SYSTEM_PARAM}"
    reinstall_finish_reboot
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
    local SYSTEM_PARAM="$1"
    curl -O "${GH_PROXY}"raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    bash reinstall.sh "${SYSTEM_PARAM}"
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
    local SYSTEM_VERSION_NAME="$1"
    local SYSTEM_PARAM="$2"

    ui echo "正在准备: ${BOLD_LIGHT_CYAN}[Bin456789] DD 脚本...${BOLD_LIGHT_WHITE}"
    ui echo "目标系统: ${BOLD_LIGHT_CYAN}${SYSTEM_VERSION_NAME}${BOLD_LIGHT_WHITE}" 

    ui line

    sleep 2

    # 执行脚本
    reinstall_Bin456789 "${SYSTEM_PARAM}"
    sleep 2
    reinstall_finish_reboot

    return 1
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
    local SYSTEM_VERSION_NAME="$1"
    local USER="$2"
    local PASS="$3"
    local PORT="$4"
    local INSTALL_FUNCTION_NAME="$5"
    local SYSTEM_PARAM="$6"

    ui echo "${LIGHT_CYAN}请最后确认您的安装选项:${BOLD_LIGHT_WHITE}"
    ui line
    ui echo "${LIGHT_CYAN}- 系统版本:${BOLD_LIGHT_WHITE} ${BOLD_RED}${SYSTEM_VERSION_NAME}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始用户:${BOLD_LIGHT_WHITE} ${YELLOW}${USER}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始密码:${BOLD_LIGHT_WHITE} ${YELLOW}${PASS}${BOLD_LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始端口:${BOLD_LIGHT_WHITE} ${YELLOW}${PORT}${BOLD_LIGHT_WHITE}"
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
    ${INSTALL_FUNCTION_NAME} "${SYSTEM_VERSION_NAME}" "${SYSTEM_PARAM}"

    return
}

# ------------------------------
# 重装系统逻辑
# ------------------------------
reinstall_logic_main() {
    ui clear

    local choice="$1"

    local USER_NAME_1="root"
    local PASS_1="LeitboGi0ro"
    local PORT_1="22"
    local FUNC_1="run_mollylau_install"

    local USER_NAME_2="Administrator"
    local PASS_2="Teddysun.com"
    local PORT_2="3389"
    local FUNC_2="run_mollylau_install"

    local USER_NAME_3="root"
    local PASS_3="123@@@"
    local PORT_3="22"
    local FUNC_3="run_bin456789_install"

    local USER_NAME_4="Administrator"
    local PASS_4="123@@@"
    local PORT_4="3389"
    local FUNC_4="run_bin456789_install"

    case "$choice" in
        "Debian 13")
            reinstall_info_config "Debian 13" "$USER_NAME_3" "$PASS_3" "$PORT_3" "$FUNC_3" "debian 13"
            return $?
        ;;
        "Debian 12")
            reinstall_info_config "Debian 12" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "debian 12"
            return $?
        ;;
        "Debian 11")
            reinstall_info_config "Debian 11" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "debian 11"
            return $?
        ;;
        "Debian 10")
            reinstall_info_config "Debian 10" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "debian 10"
            return $?
        ;;
        # ==========================================================================================
        "Ubuntu 24.04")
            reinstall_info_config "Ubuntu 24.04" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "ubuntu 24.04"
            return $?
        ;;
        "Ubuntu 22.04")
            reinstall_info_config "Ubuntu 22.04" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "ubuntu 22.04"
            return $?
        ;;
        "Ubuntu 20.04")
            reinstall_info_config "Ubuntu 20.04" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "ubuntu 20.04"
            return $?
        ;;
        "Ubuntu 18.04")
            reinstall_info_config "Ubuntu 18.04" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "ubuntu 18.04"
            return $?
        ;;
        # ==========================================================================================
        "CentOS 10")
            reinstall_info_config "CentOS 10" "$USER_NAME_3" "$PASS_3" "$PORT_3" "$FUNC_3" "centos 10"
            return $?
        ;;
        "CentOS 9")
            reinstall_info_config "CentOS 9" "$USER_NAME_3" "$PASS_3" "$PORT_3" "$FUNC_3" "centos 9"
            return $?
        ;;
        # ==========================================================================================
        "Alpine Linux")
            reinstall_info_config  "Alpine Linux" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "-alpine"
            return $?
        ;;
        # ==========================================================================================
        "Windows 11")
            reinstall_info_config "Windows 11" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" '-windows 11 -lang "cn"'
            return $?
        ;;
        "Windows 10")
            reinstall_info_config "Windows 10" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" '-windows 10 -lang "cn"'
            return $?
        ;;
        "Windows 7")
            reinstall_info_config "Windows 7" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" '-windows 7 -lang "cn"'
            return $?
        ;;
        "Windows Server 2025")
            reinstall_info_config "Windows Server 2025" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" 'windows 2025 -lang "cn"'
            return $?
        ;;
        "Windows Server 2022")
            reinstall_info_config "Windows Server 2022" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" 'windows 2022 -lang "cn"'
            return $?
        ;;
        "Windows Server 2019")
            reinstall_info_config "Windows Server 2019" "$USER_NAME_2" "$PASS_2" "$PORT_2" "$FUNC_2" 'windows 2019 -lang "cn"'
            return $?
        ;;
        0)
            # 返回上级（由 router 自动处理）
            return
        ;;
        *)
            ui_error "无效选项，请重新输入"
            sleep 1
        ;;
    esac
}