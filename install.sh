#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 一键安装脚本
# 
# @文件路径:  install.sh
# @功能描述: 环境初始化、依赖加载、主菜单渲染与路由分发
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-05
# ==============================================================================

# 严谨模式: 遇到错误即退出
set -Eeuo pipefail
trap 'error_exit "脚本在第 $LINENO 行执行失败"' ERR

# ******************************************************************************
# 基础常量定义
# ******************************************************************************
declare -rx INSTALL_DIR="/opt/VpsScriptKit"    # 安装目录
declare -rx REPO="oliver556/sh"                 # GitHub 仓库
declare -rx BIN_LINK="/usr/local/bin/vsk"       # 链接路径
declare -rx BIN_SHORT_LINK="/usr/local/bin/v"   # 存放路径
declare -rx AGREEMENT_ACCEPTED="false"          # 用户许可协议同意
SKIP_AGREEMENT="false"                          # 初始化，防止 set -u 报错

# ******************************************************************************
# 参数处理: 检查是否带有 --skip-agreement
# ******************************************************************************
for arg in "$@"; do
    if [[ "$arg" == "--skip-agreement" ]]; then
        SKIP_AGREEMENT="true"
    fi
done

# ******************************************************************************
# 颜色定义
# ******************************************************************************
# shellcheck disable=SC2155
{
    declare -rx RED=$(tput setaf 1)       # 红色 (错误/危险)
    declare -rx GREEN=$(tput setaf 2)     # 绿色 (成功/通过)
    declare -rx YELLOW=$(tput setaf 3)    # 黄色 (警告/注意)
    declare -rx BLUE=$(tput setaf 4)      # 蓝色 (信息/普通)
    declare -rx PURPLE=$(tput setaf 5)    # 紫色 (强调/特殊)
    declare -rx CYAN=$(tput setaf 6)      # 青色 (调试/路径)
    declare -rx WHITE=$(tput setaf 7)     # 白色 (正文)
    declare -rx GREY=$(tput setaf 8)      # 灰色 (正文)

    declare -rx BOLD=$(tput bold)         # 加粗 (用于标题/重点)
    declare -rx DIM=$(tput dim)           # 暗淡 (用于次要信息/注释)
    declare -rx NC=$(tput sgr0)           # 重置 (No Color，清除所有格式)

    declare -rx BOLD_RED="${BOLD}${RED}"       # 加粗红色 (错误/危险)
    declare -rx BOLD_GREEN="${BOLD}${GREEN}"   # 加粗绿色 (成功/通过)
    declare -rx BOLD_YELLOW="${BOLD}${YELLOW}" # 加粗黄色 (警告/注意)
    declare -rx BOLD_BLUE="${BOLD}${BLUE}"     # 加粗蓝色 (信息/普通)
    declare -rx BOLD_CYAN="${BOLD}${CYAN}"     # 加粗青色 (调试/路径)
    declare -rx BOLD_WHITE="${BOLD}${WHITE}"   # 加粗白色 (正文)
    declare -rx BOLD_GREY="${BOLD}${GREY}"     # 加粗灰色 (正文)
}

# ------------------------------------------------------------------------------
# 函数名: error_exit
# 功能:   退出脚本并显示错误信息
# 
# 参数:
#   $1 (string): 需要显示的文本 (必填)
# 
# 返回值:
#   1 - 失败给出相应提示
# 
# 示例:
#   error_exit "$1"
# ------------------------------------------------------------------------------
error_exit() {
    echo -e "${BOLD_RED}错误: $1${NC}" >&2
    exit 1
}

# ------------------------------------------------------------------------------
# 函数名: command_exists
# 功能:   检查命令是否存在
# 
# 参数:
#   $1 (string): 命令名称 (必填)
# 
# 返回值: 失败给出相应提示
# 
# 示例:
#   command_exists "curl"
# ------------------------------------------------------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 函数名: check
# 功能:   脚本安装条件前置检查
# 
# 参数: 无
# 
# 返回值: 失败给出相应提示
# 
# 示例:
#   check
# ------------------------------------------------------------------------------
check() {
    # 是否为 root 用户
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "请使用 root 权限运行此脚本。"
    fi

    # 系统是否安装 curl tar
    if ! command_exists "curl" || ! command_exists "tar"; then
        echo -e "${BOLD_RED}Ubuntu/Debian: apt-get install -y curl tar${NC}" >&2
        error_exit "系统中缺少 curl 或 tar，请先安装。"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: clear_version
# 功能:   清理旧版本脚本
# 
# 参数: 无
# 
# 返回值: 返回清理结果提示
# 
# 示例:
#   clear_version
# ------------------------------------------------------------------------------
clear_version() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BOLD_CYAN}检测到已存在旧版本，正在执行覆盖安装...${BOLD_WHITE}"

        rm -rf "$INSTALL_DIR" || error_exit "清理旧版本失败"
        rm -rf "$BIN_LINK"
        rm -rf "$BIN_SHORT_LINK"
        
        sleep 1
        echo
        echo -e "${BOLD_GREEN}✔$(ui_spaces 1)脚本已清理，即将覆盖安装！${BOLD_WHITE}"
        sleep 1
        clear
    fi
}

# ------------------------------------------------------------------------------
# 函数名: confirm_agreement
# 功能:   显示并确认用户协议
# 
# 参数: 无
# 
# 返回值: 继续执行 || 中断执行
# 
# 示例:
#   confirm_agreement
# ------------------------------------------------------------------------------
confirm_agreement() {

    # 如果检测到跳过参数，则直接返回
    if [[ "$SKIP_AGREEMENT" == "true" ]]; then
        echo -e "${BOLD_GREEN}检测到静默安装参数，已自动同意用户协议。${NC}"
        return 0
    fi

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

# ------------------------------------------------------------------------------
# 函数名: verify_sha256
# 功能:   SHA256 校验脚本下载是否完整
# 
# 参数:
#   $1 (blob):   压缩包文件 (必填)
#   $2 (string): 要下载的压缩包 URL (必填)
# 
# 返回值: 成功 || 失败 提示
# 
# 示例:
#   verify_sha256 "$1" "$2"
# ------------------------------------------------------------------------------
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

    echo -e "${BOLD_GREEN}✔$(ui_spaces 1)SHA256 校验通过${BOLD_WHITE}"
}

# ------------------------------------------------------------------------------
# 函数名: download_with_progress
# 功能:   SHA256 下载进度条的显示
# 
# 参数:
#   $1 (string): 要下载的压缩包 URL (必填)
#   $2 (blob):   压缩包文件 (必填)
# 
# 返回值: 进度条 || 失败提示
# 
# 示例:
#   download_with_progress "$1" "$2"
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 函数名: get_latest_release_url
# 功能:   通过 GitHub API 获取最新 Release 的 tar.gz 链接
# 
# 参数: 无
# 
# 返回值: Release 下载链接
# 
# 示例:
#   get_latest_release_url "$1" "$2"
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 函数名: download_and_extract
# 功能:   下载并解压指定的 URL
# 
# 参数:
#   $1 (string): 要下载的压缩包 URL (必填)
# 
# 返回值: 无
# 
# 示例:
#   download_and_extract "https://xxx.com/xxx.tar.gz"
# ------------------------------------------------------------------------------
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

    echo -e "${BOLD_BLUE}--> 正在解压到 $INSTALL_DIR ...${NC}"

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

# ------------------------------------------------------------------------------
# 函数名: install_latest_release
# 功能:   获取 GitHub 最新 Release，并完成下载与解压
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   install_latest_release
# ------------------------------------------------------------------------------
install_latest_release() {
    local latest_url

    latest_url=$(get_latest_release_url)
    echo -e "${BOLD_BLUE}--> 找到最新版本，开始安装...${BOLD_WHITE}"
    echo -e "    $latest_url"

    download_and_extract "$latest_url"
}

# ------------------------------------------------------------------------------
# 函数名: setup_system
# 功能:   设置文件权限并创建统一的 bin/v 链接
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   setup_system
# ------------------------------------------------------------------------------
setup_system() {
    echo -e "${BOLD_BLUE}--> 正在配置系统权限与链接...${BOLD_WHITE}"
    
    # 1. 给所有 .sh 脚本赋予执行权限，并确保 v 可执行
    find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} +
    if [ -f "$INSTALL_DIR/v" ]; then
        chmod +x "$INSTALL_DIR/v"
    fi

    # 2. 创建快捷命令链接
    mkdir -p "$(dirname "$BIN_LINK")"

    if [ -f "$INSTALL_DIR/v" ]; then
        # 核心: 无论 v 还是 vsk，全部指向 bin/v 包装器
        ln -sf "$INSTALL_DIR/v" "$BIN_LINK"
        ln -sf "$INSTALL_DIR/v" "$BIN_SHORT_LINK"
        echo -e "${BOLD_GREEN}✔$(ui_spaces 1)启动器链接已创建${BOLD_WHITE}"
    else
        # 兜底逻辑: 如果包装器没找到，尝试链接到 main.sh
        if [ -f "$INSTALL_DIR/main.sh" ]; then
            ln -sf "$INSTALL_DIR/main.sh" "$BIN_LINK"
            ln -sf "$INSTALL_DIR/main.sh" "$BIN_SHORT_LINK"
            echo -e "${BOLD_YELLOW}警告: 未找到包装器 v，已链接至 main.sh 原始脚本${BOLD_WHITE}"
        else
            error_exit "未找到可执行的主程序入口"
        fi
    fi
}

# ------------------------------------------------------------------------------
# 函数名: ui_spaces
# 功能:   生成指定数量的空格字符串
# 
# 参数:
#   $1 (number): 需要的空格数量 (可选)
# 
# 返回值: 需要的空格数量
# 
# 示例:
#   "A$(ui_spaces 2)B"
# ------------------------------------------------------------------------------
ui_spaces() {
    local count="${1:-2}"
    ((count < 0)) && count=0
    printf "%*s" "$count" ""
}

# ------------------------------------------------------------------------------
# 函数名: install_success
# 功能:   成功提示
# 
# 参数: 无
# 
# 返回值: 相应提示
# 
# 示例:
#   install_success
# ------------------------------------------------------------------------------
install_success() {
    clear

    if [[ -f "$INSTALL_DIR/banner" ]]; then
        cat "$INSTALL_DIR/banner"
    fi

    echo -e "${BOLD_GREEN}✔$(ui_spaces 1)安装完成！${BOLD_WHITE} "
    echo
    echo -e "${BOLD_GREEN}⚡$(ui_spaces 1)现在你可以通过输入 ${BOLD_YELLOW}v${BOLD_GREEN} 或 ${BOLD_YELLOW}vsk${BOLD_GREEN} 命令来启动工具。${BOLD_WHITE}"
}

# ------------------------------------------------------------------------------
# 函数名: main
# 功能:   主流程
# 
# 参数: 无
# 
# 返回值: 相应提示
# 
# 示例:
#   main
# ------------------------------------------------------------------------------
main() {
    clear

    echo -e "${BOLD_CYAN}==============================================${NC}"
    echo -e "${BOLD_WHITE}     🚀$(ui_spaces)欢迎安装 VpsScriptKit 脚本工具箱      ${NC}"
    echo -e "${BOLD_CYAN}==============================================${NC}"

    # 1. 前置检查
    check

    # 2. 询问用户协议
    # confirm_agreement

    # 3. 清理旧版本
    clear_version
    
    # 4 & 5. 获取并安装最新版本
    install_latest_release

    # 6 & 7. 配置权限与链接 (已合并)
    setup_system

    # 8. 成功提示
    install_success
}

main
