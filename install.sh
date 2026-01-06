#!/usr/bin/env bash

# =================================================================================
# @名称:         install.sh
# @功能描述:     VpsScriptKit 一键安装脚本
# @入口:         curl -sL vsk.viplee.cc | bash
# @作者:         jamison
# @版本:         1.0.0
# @创建日期:     2026-01-01
# @修改日期:     2026-01-06
#
# @依赖:         curl
# @许可证:       MIT
# =================================================================================

# 严谨模式：遇到错误即退出
set -Eeuo pipefail
trap 'error_exit "脚本在第 $LINENO 行执行失败"' ERR

# ------------------------------
# 基础配置
# ------------------------------
INSTALL_DIR="/opt/VpsScriptKit"   # 安装目录
REPO="oliver556/sh"               # 仓库地址
AGREEMENT_ACCEPTED="false"        # 用户许可协议同意
BIN_LINK="/usr/local/bin/vsk"     # 
BIN_SHORT_LINK="/usr/local/bin/v" # 

# ------------------------------
# 颜色定义 (使用 tput 确保兼容性) 
# ------------------------------
BOLD_WHITE=$(tput bold)$(tput setaf 7)
BOLD_RED=$(tput bold)$(tput setaf 1)
BOLD_GREEN=$(tput bold)$(tput setaf 2)
BOLD_YELLOW=$(tput bold)$(tput setaf 3)
BOLD_BLUE=$(tput bold)$(tput setaf 4)
BOLD_CYAN=$(tput bold)$(tput setaf 6)
RESET=$(tput sgr0)

# ------------------------------
# error_exit
# 
# @描述: 本函数用于: 退出脚本并显示错误信息
# @参数: $1: string - 错误信息
# @返回值: 失败给出相应提示
# @示例: error_exit "$1"
# ------------------------------
error_exit() {
    echo -e "${BOLD_RED}错误: $1${RESET}" >&2
    exit 1
}

# ------------------------------
# command_exists
# @描述: 本函数用于: 检查命令是否存在
# @参数: $1: string - 命令名称
# @返回值: 失败给出相应提示
# @示例: command_exists "curl"
# ------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------
# check
# @描述: 本函数用于: 脚本安装条件前置检查
# @参数: 无
# @返回值: 失败给出相应提示
# @示例: check
# ------------------------------
check() {
    # 是否为 root 用户
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "请使用 root 权限运行此脚本。"
    fi

    # 系统是否安装 curl tar
    if ! command_exists "curl" || ! command_exists "tar"; then
        echo -e "${BOLD_RED}Ubuntu/Debian: apt-get install -y curl tar${RESET}" >&2
        error_exit "系统中缺少 curl 或 tar，请先安装。"
    fi
}

# ------------------------------
# clear_version
# @描述: 本函数用于: 清理旧版本
# @参数: 无
# @返回值: 返回清理结果提示
# @示例: clear_version
# ------------------------------
clear_version() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BOLD_CYAN}检测到已存在旧版本，正在执行覆盖安装...${BOLD_WHITE}"

        rm -rf "$INSTALL_DIR" || error_exit "清理旧版本失败"
        rm -rf "$BIN_LINK"
        rm -rf "$BIN_SHORT_LINK"
        
        sleep 1
        echo
        echo -e "${BOLD_CYAN}✅ 脚本已清理，即将覆盖安装！${BOLD_WHITE}"
        sleep 2
        clear
    fi
}

# ------------------------------
# confirm_agreement
# @描述: 本函数用于: 显示并确认用户协议
# @参数: 无
# @返回值: 继续执行 || 中断执行
# @示例: confirm_agreement
# ------------------------------
confirm_agreement() {
    clear
    echo -e "${BOLD_BLUE}欢迎使用 VpsScriptKit 脚本工具箱${BOLD_WHITE}"
    echo -e "${BOLD_YELLOW}在继续安装之前，请先阅读并同意用户协议。${BOLD_WHITE}"
    echo "─────────────────────────────────────────────────────"
	echo "用户许可协议: https://"
    echo "─────────────────────────────────────────────────────"

    # 读取用户输入
    local choice
    read -rp "您是否同意以上条款？(y/n): " choice
    echo

    # 将输入转换为小写以便比较
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    # 如果用户同意，将全局变量设置为 "true"
    if [[ "$choice" == "y" ]]; then
        # 如果用户同意，将全局变量设置为 "true"
        AGREEMENT_ACCEPTED="true"
        echo -e "${BOLD_GREEN}您已同意用户协议，安装将继续...${BOLD_WHITE}"
    fi

    if [[ "$AGREEMENT_ACCEPTED" != "true" ]]; then
        echo
        echo -e "${BOLD_RED}已拒绝用户协议，已终止安装。${BOLD_WHITE}"
        rm -rf "$INSTALL_DIR"
        rm -rf "$BIN_LINK"
        rm -rf "$BIN_SHORT_LINK"
        sleep 1
        clear
        exit 1
    fi
}

# ------------------------------
# verify_sha256
# @描述: 本函数用于: SHA256 校验
# @参数:
#       $1: blob - 压缩包文件
#       $2: string - 要下载的压缩包 URL
# @返回值: 成功 || 失败 提示
# @示例: verify_sha256 "$1" "$2"
# ------------------------------
verify_sha256() {
    local file="$1"
    local sha_url="$2"

    echo -e "${BOLD_BLUE}--> 正在校验文件完整性...${BOLD_WHITE}"

    local expected
    expected=$(curl -fsSL "$sha_url" | awk '{print $1}') || error_exit "获取 SHA256 失败"

    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')

    if [[ "$expected" != "$actual" ]]; then
        error_exit "SHA256 校验失败，可能遭到劫持！"
    fi

    echo -e "${BOLD_GREEN}✅ SHA256 校验通过${BOLD_WHITE}"
}

# ------------------------------
# download_with_progress
# @描述: 本函数用于: 下载进度条的显示
# @参数:
#       $1: string - 要下载的压缩包 URL
#       $2: blob - 压缩包文件
# @返回值: 进度条 || 失败提示
# @示例: download_with_progress "$1" "$2"
# ------------------------------
download_with_progress() {
    local url="$1"
    local output="$2"

    curl \
        --fail \
        --location \
        --progress-bar \
        --connect-timeout 10 \
        "$url" \
        -o "$output" || error_exit "下载发行版压缩包失败！$url"
}

# ------------------------------
# show_install_path
# @描述: 本函数用于: 安装路径提示
# @参数:
#       $1: string - 要下载的压缩包 URL
#       $2: blob - 压缩包文件
# @返回值: 安装路径信息展示
# @示例: show_install_path
# ------------------------------
show_install_path() {
    echo
    echo -e "${BOLD_CYAN}📂 安装路径信息:${BOLD_WHITE}"
    echo -e "  主目录: ${BOLD_YELLOW}$INSTALL_DIR${BOLD_WHITE}"
    echo -e "  主程序: ${BOLD_YELLOW}$INSTALL_DIR/core/main.sh${BOLD_WHITE}"
    echo -e "  快捷命令:"
    echo -e "    - ${BOLD_YELLOW}vsk${BOLD_WHITE} -> $BIN_LINK"
    echo -e "    - ${BOLD_YELLOW}v${BOLD_WHITE}   -> $BIN_SHORT_LINK"
}

# ------------------------------
# get_latest_release_url
# @描述: 本函数用于: 通过 GitHub API 获取最新 Release 的 tar.gz 链接
# @参数: 无
# @返回值:  Release 下载链接
# @示例: get_latest_release_url
# ------------------------------
get_latest_release_url() {
    echo -e "${BOLD_BLUE}--> 正在查询最新版本...${BOLD_WHITE}" >&2

    # 调用 GitHub API 获取最新 Release 的信息
    local LATEST_RELEASE_JSON
    LATEST_RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest") || error_exit "无法连接 GitHub API"

    if echo "$LATEST_RELEASE_JSON" | grep -q '"message"'; then
        error_exit "GitHub API 返回错误，可能触发限速或仓库不存在"
    fi

    # 从返回的 JSON 中解析出 .tar.gz 文件的下载链接
    local TARBALL_URL
    TARBALL_URL=$(echo "$LATEST_RELEASE_JSON" | grep "browser_download_url" | grep "\.tar\.gz\"" | cut -d '"' -f 4)

    # 检查是否成功获取到 URL
    if [ -z "$TARBALL_URL" ]; then
        error_exit "无法找到最新的发行版下载链接！请检查仓库 Release 页面。"
    fi

    # 将找到的 URL 作为函数的唯一标准输出
    echo "$TARBALL_URL"
}

# ------------------------------
# download_and_extract
# @描述: 本函数用于: 下载并解压指定的 URL
# @参数: $1: string - 要下载的压缩包 URL
# @返回值: 无
# @示例: install_vsk_download_and_extract "https://xxx.com/xxx.tar.gz"
# ------------------------------
download_and_extract() {
    local tarball_url="$1"

    echo -e "${BOLD_BLUE}--> 正在从远程获取安装包...${BOLD_WHITE}" >&2

    # 创建一个临时文件来存放下载的压缩包
    local tmp_file
    tmp_file=$(mktemp)

    # 使用传入的 URL 进行下载
    # curl -L "$tarball_url" -o "$tmp_file" || error_exit "下载发行版压缩包失败！"
    download_with_progress "$tarball_url" "$tmp_file"

    # ===========================
    # [新增] 下载完成后校验
    # ===========================
    verify_sha256 "$tmp_file" "${tarball_url}.sha256"

    # 创建安装目录
    mkdir -p "$INSTALL_DIR" || error_exit "创建安装目录 $INSTALL_DIR 失败！"

    echo -e "${BOLD_BLUE}--> 正在解压到 $INSTALL_DIR ...${RESET}"

    # ===========================
    # [修改说明]
    # 修复 GitHub Release 多一层目录的问题
    # ===========================
    tar -xzf "$tmp_file" -C "$INSTALL_DIR" --strip-components=1 || error_exit "解压文件失败！"

    # # 解压到目标目录 (注意：没有 --strip-components=1)
    # tar -xzf "$tmp_file" -C "$INSTALL_DIR" || error_exit "解压文件失败！"

    # 清理临时文件
    rm -f "$tmp_file"
}

# ------------------------------
# install_latest_release
# @描述: 本函数用于: 获取 GitHub 最新 Release，并完成下载与解压
# @参数: 无
# @返回值: 无
# @示例: install_latest_release
# ------------------------------
install_latest_release() {
    local latest_url

    latest_url=$(get_latest_release_url)
    echo -e "${BOLD_BLUE}--> 找到最新版本，开始安装...${BOLD_WHITE}"
    echo -e "    $latest_url"

    download_and_extract "$latest_url"
}


# ------------------------------
# setup_system
# @描述: 本函数用于: 设置文件权限并创建统一的 bin/v 链接
# @参数: 无
# @返回值: 无
# @示例: setup_system
# ------------------------------
setup_system() {
    echo -e "${BOLD_BLUE}--> 正在配置系统权限与链接...${BOLD_WHITE}"
    
    # 1. 给所有 .sh 脚本赋予执行权限，并确保 bin/v 可执行
    find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} +
    if [ -f "$INSTALL_DIR/bin/v" ]; then
        chmod +x "$INSTALL_DIR/bin/v"
    fi

    # 2. 创建快捷命令链接
    mkdir -p "$(dirname "$BIN_LINK")"

    if [ -f "$INSTALL_DIR/bin/v" ]; then
        # 核心: 无论 v 还是 vsk，全部指向 bin/v 包装器
        ln -sf "$INSTALL_DIR/bin/v" "$BIN_LINK"
        ln -sf "$INSTALL_DIR/bin/v" "$BIN_SHORT_LINK"
        echo -e "${BOLD_GREEN}✅ 启动器链接已创建${BOLD_WHITE}"
    else
        # 兜底逻辑: 如果包装器没找到，尝试链接到 main.sh
        if [ -f "$INSTALL_DIR/core/main.sh" ]; then
            ln -sf "$INSTALL_DIR/core/main.sh" "$BIN_LINK"
            ln -sf "$INSTALL_DIR/core/main.sh" "$BIN_SHORT_LINK"
            echo -e "${BOLD_YELLOW}警告: 未找到包装器 bin/v，已链接至 main.sh 原始脚本${BOLD_WHITE}"
        else
            error_exit "未找到可执行的主程序入口"
        fi
    fi
}

# # ------------------------------
# # set_permissions
# # @描述: 本函数用于: 设置权限
# # @参数: 无
# # @返回值: 无
# # @示例: set_permissions
# # ------------------------------
# set_permissions() {
#     # 设置执行权限并创建快捷命令
#     echo -e "${BOLD_BLUE}--> 正在设置文件权限...${BOLD_WHITE}"
#     find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} +
# }

# # ------------------------------
# # quick_start
# # @描述: 本函数用于: 创建快捷命令
# # @参数: 无
# # @返回值: 无
# # @示例: quick_start
# # ------------------------------
# quick_start() {
#     echo -e "${BOLD_BLUE}--> 正在创建快速启动命令...${BOLD_WHITE}"

#     # ===========================
#     # [新增] 确保目录存在
#     # ===========================
#     mkdir -p "$(dirname "$BIN_LINK")"

#     if [ -f "$INSTALL_DIR/core/main.sh" ]; then
#         # 指向主入口 main.sh
#         ln -sf "$INSTALL_DIR/core/main.sh" "$BIN_LINK"
#         ln -sf "$INSTALL_DIR/core/main.sh" "$BIN_SHORT_LINK"
#     else
#         echo -e "${BOLD_YELLOW}警告: 未在仓库找到 main.sh，跳过创建快捷命令。${BOLD_WHITE}"
#     fi
# }

# ------------------------------
# install_success
# @描述: 本函数用于: 成功提示
# @参数: 无
# @返回值: 相应提示
# @示例: install_success
# ------------------------------
install_success() {
    clear

    cat <<-EOF
+----------------------------------------------------------------------------------------------------+
|  ██╗     ██╗█████████╗███████╗  ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗  ██╗  ██╗██╗████████╗ |
|  ██╗     ██║██╔════██║██╔════╝  ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝  ██║ ██╔╝██║╚══██╔══╝ |
|   ██╗   ██╗ █████████║███████╗  ███████╗██║     ██████╔╝██║██████╔╝   ██║     █████╔╝ ██║   ██║    |
|    ██╗ ██╗  ██╔══════╝╚════██║  ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║     ██╔═██╗ ██║   ██║    |
|     ████╗  ║██║       ███████║  ███████║╚██████╗██║  ██║██║██║        ██║     ██║  ██╗██║   ██║    |
|     ╚═══╝  ╚══╝       ╚══════╝  ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝    |
+----------------------------------------------------------------------------------------------------+
EOF
    echo -e "${BOLD_GREEN}✅ 安装完成！${BOLD_WHITE} "
    echo -e "${BOLD_GREEN}   现在你可以通过输入 ${BOLD_YELLOW}v${BOLD_GREEN} 或 ${BOLD_YELLOW}vsk${BOLD_GREEN} 命令来启动工具。。${BOLD_WHITE}"

    show_install_path
}

# ------------------------------
# main
# @描述: 本函数用于: 主流程
# @参数: 无
# @返回值: 无
# @示例: main
# ------------------------------
main() {
    clear

    echo -e "${BOLD_CYAN}==============================================${RESET}"
    echo -e "${BOLD_WHITE}     🚀 欢迎安装 VpsScriptKit 脚本工具箱      ${RESET}"
    echo -e "${BOLD_CYAN}==============================================${RESET}"

    # 1. 前置检查
    check

    # 2. 询问用户协议
    confirm_agreement

    # 3. 清理旧版本
    clear_version
    
    # 4 & 5. 获取并安装最新版本
    install_latest_release

    # # 6. 设置权限
    # set_permissions

    # # 7. 创建快速启动命令
    # quick_start
    
    # 6 & 7. 配置权限与链接 (已合并)
    setup_system

    # 8. 成功提示
    install_success
}

main
