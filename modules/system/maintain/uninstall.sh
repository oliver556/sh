#!/usr/bin/env bash

# =================================================================================
# @名称:        uninstall.sh
# @功能描述:     VpsScriptKit 卸载脚本
# @作者:        Jamison
# @版本:        1.3.0
# @修改日期:     2026-01-07
# @许可证:       MIT
# =================================================================================
# 严谨模式：遇到错误即退出
set -Eeuo pipefail
trap 'echo -e "\n${BOLD_RED}❌ 卸载过程中出现异常${RESET}" >&2' ERR

# ******************************************************************************
# 环境初始化
# ******************************************************************************
source "${BASE_DIR}/lib/env.sh"

# ******************************************************************************
# 基础配置
# ******************************************************************************
# BIN_PATHS=(
#     "/usr/local/bin/v"
#     "/usr/local/bin/vsk"
#     "/usr/bin/v"
#     "/usr/bin/vsk"
# )

# ------------------------------------------------------------------------------
# 函数名: do_uninstall
# 功能:  卸载脚本
# 
# 参数: 无
# 
# 返回值:
#   0 - 取消卸载
#   1 - 执行卸载
# 
# 示例:
#   do_uninstall
# ------------------------------------------------------------------------------
do_uninstall() {
    # if [[ "$(id -u)" -ne 0 ]]; then
    #     echo -e "${BOLD_RED}错误：请使用 root 权限执行卸载${RESET}"
    #     return 1
    # fi
    
    if ! check_root; then
        # TODO 需要验证
        # 原本有 return 1，但是该函数(check_root)只需要return 即可。
        return 1
    fi

    ui clear
    ui line_3
    ui echo "${BOLD_RED}        ⚠️$(ui_spaces 4)正在卸载 VpsScriptKit${RESET}"
    ui line_3
    ui blank
    ui echo "${BOLD_WHITE}该操作将完全移除脚本及所有命令。${RESET}"
    ui blank

    # TODO 改成调用函数
    # if ! ui_confirm "确认开始卸载脚本？"; then
    #     return 1
    # fi
    printf "${BOLD_CYAN}确认继续卸载？(y/N): ${RESET}"

    read -r confirm < /dev/tty || confirm="n"
    confirm="${confirm,,}"

    if [[ "$confirm" != "y" ]]; then
        echo
        ui_info "已取消卸载。"
        echo
        return 0
    fi

    ui blank

    ui_tip "正在清理系统..."

    for path in "${BIN_PATHS[@]}"; do
        [[ -e "$path" || -L "$path" ]] && rm -f "$path"
    done

    [[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"

    # hash -r 2>/dev/null || true

    ui blank
    ui_success "VpsScriptKit 已彻底卸载完成"
    ui blank
    ui_success "所有组件已清理，感谢使用。"
    sleep 2
    clear
    return 0
}

# ------------------------------
# 脚本入口
# ------------------------------
do_uninstall "$@"

# exit 0
