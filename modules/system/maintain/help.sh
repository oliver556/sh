#!/usr/bin/env bash=

# ==============================================================================
# VpsScriptKit - v 命令参考用例
# 
# @文件路径: modules/system/maintain/help.sh
# @功能描述: 脚本子管理菜单中心
# 
# @作者:    Jamison
# @版本:    0.1.0
# @创建日期: 2026-01-30
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: _print_help_line
# 功能:   打印强对齐的帮助行 (Curl 风格)
# 逻辑:   计算纯文本长度 -> 补齐空格 -> 打印颜色
# ------------------------------------------------------------------------------
_print_help_line() {
    local short="$1"
    local long="$2"
    local args="$3"
    local desc="$4"
    
    # 1. 构建左侧命令字符串
    local left_text=""
    
    if [[ -n "$short" ]]; then
        # 模式 A: 短参+长参 (如 " -h, --help") -> 1格缩进
        left_text=" ${short}, ${long}"
    elif [[ "$long" == -* ]]; then
        # 模式 B: 纯长参 (如 "     --version") -> 对齐到长参位置
        left_text="     ${long}"
    else
        # 模式 C: 子命令/例子 (如 " clean") 
        # [修正] 以前是缩进2格 ("  ${long}")，现在改为1格，强制与上方 "-h" 对齐
        left_text=" ${long}"
    fi

    # 2. 追加参数
    if [[ -n "$args" ]]; then
        left_text="${left_text} ${args}"
    fi

    # 3. 计算填充 (硬对齐到第 33 列)
    local align_width=33
    local text_len=${#left_text}
    local pad_len=$((align_width - text_len))
    
    # 兜底：如果命令太长，至少留 1 个空格
    if [[ $pad_len -lt 1 ]]; then pad_len=1; fi

    # 4. 输出
    printf "${CYAN}%s${NC}%*s%s\n" "$left_text" "$pad_len" "" "${desc}"
}

# ------------------------------------------------------------------------------
# 函数名: v_help
# 功能:   分模块显示帮助信息 (混合模式：默认看目录，指定看详情)
# ------------------------------------------------------------------------------
v_help() {
    print_clear
    local target="${1:-summary}" # 默认为 summary (目录模式)

    print_blank
    echo "Usage: v [options] [command] <args>"
    print_blank

    # ==========================================================================
    # 模式 A: 目录模式 (Summary) - 对应 v -h
    # ==========================================================================
    if [[ "$target" == "summary" ]]; then
        echo "Options:"
        _print_help_line "-h" "--help"    "<category>" "显示帮助 (可选: all, software, system, docker)"
        _print_help_line "-v" "--version" ""           "查看脚本版本"
        _print_help_line "-u" "--update"  ""           "更新脚本至最新版"
        print_blank

        echo "This is not the full help, this menu is stripped into categories."
        echo ""
        echo "Help Categories:"
        # 这里用你的对齐函数，列出分类，而不是列出命令
        _print_help_line "" "software" "" "查看 [软件管理] 相关命令"
        _print_help_line "" "system"   "" "查看 [系统设置] 相关命令"
        _print_help_line "" "docker"   "" "查看 [Docker] 相关命令"
        print_blank
        
        echo "Use \"v -h category\" to get an overview of a specific category."
        echo "For all options use \"v -h all\"."
        return 0
    fi

    # ==========================================================================
    # 模式 B: 详情模式 (Detail) - 对应 v -h all / v -h docker
    # ==========================================================================
    
    # 1. 软件管理
    if [[ "$target" == "all" || "$target" == "software" ]]; then
        echo "Software Management:"
        _print_help_line "i"  "install"   "<pkg...>" "安装软件 (如: v i curl git)"
        _print_help_line "rm" "remove"    "<pkg...>" "卸载软件"
        _print_help_line ""   "clean"     ""         "清理系统垃圾/缓存"
    fi

    # 2. 系统设置
    if [[ "$target" == "all" || "$target" == "system" ]]; then
        echo "System & Network:"
        _print_help_line ""   "dd"        ""       "重装系统 (DD模式)"
        _print_help_line ""   "swap"      "<size>" "设置虚拟内存 (单位MB)"
        _print_help_line ""   "bbr"       ""       "打开 BBR3 管理面板"
        _print_help_line ""   "ssl"       ""       "SSL 证书申请与管理"
    fi

    # 3. Docker 管理
    if [[ "$target" == "all" || "$target" == "docker" ]]; then
        echo "Docker Management:"
        _print_help_line ""   "docker install"   "" "一键安装 Docker 环境"
        _print_help_line ""   "docker uninstall" "" "卸载 Docker 环境"
    fi

    # 4. 示例 (仅在 all 模式显示)
    if [[ "$target" == "all" ]]; then
        echo "Examples:"
        _print_help_line ""   "v install curl" "" "安装基础工具"
        _print_help_line ""   "v swap 2048"    "" "设置 2GB 虚拟内存"
    fi
}