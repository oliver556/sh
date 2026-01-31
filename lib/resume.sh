#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 通用断点续传模块
#
# @文件路径: lib/resume.sh
# @功能描述: 提供系统重启后的任务自动接管功能，支持 Login Shell 与 Interactive Shell
#           通过注入 .bashrc/.profile 实现无感知的断点续传。
#
# @作者:    Jamison
# @版本:    1.1.0
# @创建日期: 2026-01-30
# ==============================================================================

# ******************************************************************************
# 全局常量定义
# ******************************************************************************
# 定义用于存储断点状态（函数名及参数）的文件路径
: "${HOME:=/root}"
RESUME_STATE_FILE="${HOME}/.vsk_resume_state"

# 定义注入到系统配置文件中的起始标记（用于定位和清理）
RESUME_MARK_START="#_VSK_AUTO_RESUME_START_"

# 定义注入到系统配置文件中的结束标记
RESUME_MARK_END="#_VSK_AUTO_RESUME_END_"

# ------------------------------------------------------------------------------
# 函数名: _get_hook_content
# 功能:   生成用于注入到 Shell 配置文件中的钩子脚本内容
# 内部函数: 是
#
# 参数:
#   $1 (string) - 需要自动拉起的主脚本绝对路径
#
# 返回值:
#   String - 包含检测逻辑的 Shell 代码块
# ------------------------------------------------------------------------------
_get_hook_content() {
    local script_path="$1"
    cat << EOF
$RESUME_MARK_START
if [ -f "$RESUME_STATE_FILE" ]; then
    if [ -t 1 ]; then
        echo "⚡ [VSK] 正在唤醒脚本..."
        # 稍微延迟，等待终端完全就绪
        sleep 1
        bash "$script_path" --resume
    fi
fi
$RESUME_MARK_END
EOF
}

# ------------------------------------------------------------------------------
# 函数名: _clean_hook
# 功能:   从指定文件中清理旧的 VSK 恢复钩子
# 内部函数: 是
#
# 参数:
#   $1 (string) - 目标文件路径 (如 /root/.bashrc)
# ------------------------------------------------------------------------------
_clean_hook() {
    local target_file="$1"
    if [ -f "$target_file" ]; then
        # 使用 sed 删除标记块
        sed -i "/$RESUME_MARK_START/,/$RESUME_MARK_END/d" "$target_file"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: _inject_hook_append
# 功能:   向文件末尾追加钩子 (适用于 .profile/.bash_profile)
# 内部函数: 是
#
# 参数:
#   $1 (string) - 目标文件路径
#   $2 (string) - 钩子内容
# ------------------------------------------------------------------------------
_inject_hook_append() {
    local target_file="$1"
    local content="$2"
    
    # 文件不存在则创建
    touch "$target_file"
    
    # 先清理
    _clean_hook "$target_file"
    
    # 追加到末尾
    echo "$content" >> "$target_file"
}

# ------------------------------------------------------------------------------
# 函数名: _inject_hook_prepend
# 功能:   向文件头部插入钩子 (适用于 .bashrc，防止因 return 导致不执行)
# 内部函数: 是
#
# 参数:
#   $1 (string) - 目标文件路径
#   $2 (string) - 钩子内容
# ------------------------------------------------------------------------------
_inject_hook_prepend() {
    local target_file="$1"
    local content="$2"
    
    touch "$target_file"
    _clean_hook "$target_file"
    
    # 使用临时文件将内容插入到头部
    local temp_file
    temp_file=$(mktemp)
    
    echo "$content" > "$temp_file"
    cat "$target_file" >> "$temp_file"
    mv "$temp_file" "$target_file"
}

# ------------------------------------------------------------------------------
# 函数名: set_resume_point
# 功能:   设置断点续传
#         保存当前状态，并将启动钩子注入到系统配置文件中
#
# 参数:
#   $1 (string) - 重启后需要执行的回调函数名
#   $@ (string) - [可选] 传递给回调函数的参数
#
# 示例:
#   set_resume_point "system_tune_resume" "arg1"
# ------------------------------------------------------------------------------
set_resume_point() {
    local target_func="$1"
    shift
    local target_args="$*"
    
    # 保存状态文件
    echo "${target_func} ${target_args}" > "$RESUME_STATE_FILE"
    
    local main_script_path
    main_script_path=$(readlink -f "$0")
    local hook_content
    hook_content=$(_get_hook_content "$main_script_path")
    
    # 1. 处理 Login Shell 配置 (profile)
    # 如果用户有 .bash_profile，bash 会忽略 .profile，所以优先写 .bash_profile
    if [ -f "${HOME}/.bash_profile" ]; then
        _inject_hook_append "${HOME}/.bash_profile" "$hook_content"
    else
        _inject_hook_append "${HOME}/.profile" "$hook_content"
    fi
    
    # 2. 处理 Interactive Shell 配置 (bashrc)
    # 使用 _inject_hook_prepend 把它放到第一行
    # 防止因为文件中间的 'return' 导致钩子失效
    _inject_hook_prepend "${HOME}/.bashrc" "$hook_content"
    
    # print_success "[系统] 已设置断点续传 (路径: $main_script_path)"
}

# ------------------------------------------------------------------------------
# 函数名: clear_resume_point
# 功能:   清理断点续传
#         删除状态文件，并移除所有系统配置文件中的钩子
#
# 参数:
#   无
# ------------------------------------------------------------------------------
clear_resume_point() {
    rm -f "$RESUME_STATE_FILE"
    _clean_hook "${HOME}/.bashrc"
    _clean_hook "${HOME}/.profile"
    _clean_hook "${HOME}/.bash_profile"
}

# ------------------------------------------------------------------------------
# 函数名: check_resume_entry
# 功能:   接盘检查入口
#         在脚本启动时调用，检查是否存在恢复信号，如果存在则跳转执行对应任务
#
# 参数:
#   $1 (string) - 脚本传入的第一个参数 (通常用于检测 --resume)
#
# 示例:
#   check_resume_entry "$@"
# ------------------------------------------------------------------------------
check_resume_entry() {
    local input_arg="$1"
    
    if [[ "$input_arg" == "--resume" ]] && [[ -f "$RESUME_STATE_FILE" ]]; then
        local file_content
        file_content=$(cat "$RESUME_STATE_FILE")
        local func_name
        func_name=$(echo "$file_content" | awk '{print $1}')
        local func_args
        func_args=$(echo "$file_content" | cut -d' ' -f2-)
        
        # 立即清理
        clear_resume_point
        
        print_line -c "="
        print_step "正在继续执行任务: $func_name"
        print_line -c "="
        sleep 1
        
        if declare -f "$func_name" > /dev/null; then
            local -a args_array
            read -r -a args_array <<< "$func_args"
            "$func_name" "${args_array[@]}"
        else
            print_error "错误: 无法找到恢复函数 [$func_name]"
        fi
        exit 0
    fi
}