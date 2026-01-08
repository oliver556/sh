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
# 名称: MollyLau 脚本
# @描述: 本函数用于安装 MollyLau 脚本
# @参数: $1: string - 脚本执行后缀补充 (e.g., "debian 12")
#
# @GitHub 地址：https://github.com/leitbogioro/Tools
# @示例: reinstall_MollyLau "debian 12"
# ------------------------------
reinstall_MollyLau() {
    local SYSTEM_PARAM="$1"
    wget --no-check-certificate -qO InstallNET.sh "${GH_PROXY}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh
    bash InstallNET.sh -"${SYSTEM_PARAM}"
}

# ------------------------------
# 名称: MollyLau 脚本安装逻辑 ①
# @描述: 本函数用于安装 MollyLau 脚本。
#
# @参数 $1: 系统版本全名 (e.g., "Debian 12")
# @参数 $2: 脚本执行后缀补充 (e.g., "debian 12")
#
# @示例: run_mollylau_install "Debian 12" "debian 12"
# ------------------------------
run_mollylau_install() {
    ui echo "走到安装逻辑了"

    local SYSTEM_VERSION_NAME="$1"
    local SYSTEM_PARAM="$2"

    ui echo "正在检查系统是否安装有必要环境..."

    # 确保 wget 环境就绪
    ensure_wget || exit 1

    sleep 1

    ui echo "正在为您准备 [MollyLau] DD 脚本..."
    ui echo "目标系统: ${SYSTEM_VERSION_NAME}" 

    ui line

    sleep 2

    # 实际执行时取消下方注释
    # reinstall_MollyLau "${SYSTEM_PARAM}"
    # sleep 2
    # reinstall_finish_reboot

    # 如果用于测试阶段想看回车返回，则返回 0
    return 0
}

# ------------------------------
# 名称: bin456789 脚本
# @描述: 本函数用于安装 bin456789 脚本
# @参数: $1: string - 脚本执行后缀补充 (e.g., "debian 12")
#
# @GitHub 地址：https://github.com/bin456789/reinstall
# @示例: reinstall_bin456789 "debian 12"
# ------------------------------
reinstall_bin456789() {
    local SYSTEM_PARAM="$1"
    curl -O "${GH_PROXY}"raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    bash reinstall.sh "${SYSTEM_PARAM}"
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

    ui echo "${LIGHT_CYAN}请最后确认您的安装选项:${LIGHT_WHITE}"
    ui line
    ui echo "${LIGHT_CYAN}- 系统版本:${LIGHT_WHITE} ${BOLD_RED}${SYSTEM_VERSION_NAME}${LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始用户:${LIGHT_WHITE} ${YELLOW}${USER}${LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始密码:${LIGHT_WHITE} ${YELLOW}${PASS}${LIGHT_WHITE}"
    ui echo "${LIGHT_CYAN}- 初始端口:${LIGHT_WHITE} ${YELLOW}${PORT}${LIGHT_WHITE}"
    ui line

    ui blank

    ui echo "${BOLD_RED}警告: 这将清除目标服务器上的所有数据！${LIGHT_WHITE}"
    ui echo "${BOLD_RED}请务必记录好上述密码，以免重装后失联。${LIGHT_WHITE}"

    # if ! ui_confirm; then
        # return 1
    # fi

    if ! ui_confirm "确认开始重装系统？"; then
        return 1
    fi

    ui blank

    ui_info "确认完毕，准备开始 DD！"

    ui line
    ui echo "${LIGHT_CYAN}马上开始重装系统${LIGHT_WHITE}"
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
    # while true; do
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

    case "$choice" in
        "Debian 12")
            # 展示要安装的系统信息内容给用户确认
            # reinstall_info_config "Debian 12" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "debian 12"
            reinstall_info_config "Debian 12" "$USER_NAME_1" "$PASS_1" "$PORT_1" "$FUNC_1" "debian 12"
            return $?
            # ui_wait
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
    # done
}