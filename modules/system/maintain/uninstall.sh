#!/usr/bin/env bash

# =================================================================================
# @名称:        uninstall.sh
# @功能描述:     VpsScriptKit 卸载脚本
# @作者:        Jamison
# @版本:        1.3.0
# @修改日期:     2026-01-07
# @许可证:       MIT
# =================================================================================

set -Eeuo pipefail

# ******************************************************************************
# 加载必要函数库（需要完全退出脚本，卸载为独立 exec 执行的，所以需要重新引入）
# ******************************************************************************
LIBS=(
    "env.sh"        # 全局环境变量与常量配置
    "ui.sh"         # UI 渲染工具 - 函数库
    "interact.sh"   # 交互确认工具 - 函数库

    "utils.sh"      # 全局通用工具 - 函数库
    "check.sh"      # 通用检测工具 - 函数库
    "network.sh"    # 网络信息工具 - 函数库
    "system.sh"     # 系统信息工具 - 函数库
    "validate.sh"   # 能力检测工具 - 函数库
    "router.sh"     # 路由模块工具 - 函数库
)

# 循环加载并检查，避免 source 不存在的文件导致报错退出
for lib in "${LIBS[@]}"; do
    if [[ -f "${BASE_DIR}/lib/$lib" ]]; then
        source "${BASE_DIR}/lib/$lib"
    fi
done

# ******************************************************************************
# 基础配置
# ******************************************************************************
# INSTALL_DIR="/opt/VpsScriptKit"

BIN_PATHS=(
    "/usr/local/bin/v"
    "/usr/local/bin/vsk"
    "/usr/bin/v"
    "/usr/bin/vsk"
)


trap 'echo -e "\n${BOLD_RED}❌ 卸载过程中出现异常${RESET}" >&2' ERR

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
