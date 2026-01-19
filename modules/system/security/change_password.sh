#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 修改系统用户密码
#
# @文件路径: modules/system/security/change_password.sh
# @功能描述:
#   提供安全的用户密码修改功能，支持 root 与非 root 用户
#
# @作者: Jamison
# @版本: 1.0.0
# @创建日期: 2026-01-12
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: guard_change_password
# 功能:   修改密码前的前置检查（守卫函数）
# 
# 参数:
#   无
# 
# 返回值:
#   0 - 允许执行修改密码操作
#   1 - 不满足执行条件
# 
# 示例:
#   guard_change_password
# ------------------------------------------------------------------------------
guard_change_password() {
    print_clear

    if ! has_cmd passwd; then
        print_error "系统未检测到 passwd 命令，无法修改密码"
        return 1
    fi
    
    change_password "$@"
    
    return $?
}

# ------------------------------------------------------------------------------
# 函数名: change_password
# 功能:   修改系统用户密码（行为型）
# 
# 参数:
#   $1 (string): 用户名（可选）
#               - root 用户：可指定其他用户
#               - 非 root 用户：忽略该参数，只能修改自身
# 
# 返回值:
#   0 - 密码修改成功
#   1 - 修改失败
# 
# 示例:
#   change_password
#   change_password "testuser"
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 函数名: change_password
# 功能:   交互式修改用户密码
# 
# 参数:
#   -u | --user (字符串): 指定目标用户名 (仅 root 可用)
#   $1          (字符串): (兜底) 直接传入用户名
# 
# 示例:
#   change_password                 # 修改当前用户(root改root, 普通改自己)
#   change_password -u www          # root 修改 www 用户
#   change_password "admin"         # 简写模式
# ------------------------------------------------------------------------------
# shellcheck disable=SC2120
change_password() {
    local target_user=""
    
    # 1. 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--user)
                target_user="$2"
                shift 2
                ;;
            *)
                # 兜底：支持 change_password "username" 这种写法
                if [[ -z "$target_user" ]]; then
                    target_user="$1"
                fi
                shift 1
                ;;
        esac
    done

    # 2. 确定目标用户逻辑
    if is_root; then
        # === Root 用户逻辑 ===
        if [[ -z "$target_user" ]]; then
            # 如果没指定，默认为 root
            target_user="root"
        fi
    else
        # === 普通用户逻辑 ===
        # 强制只能修改自己，忽略传入的参数
        local current_user
        current_user=$(whoami)
        
        if [[ -n "$target_user" ]] && [[ "$target_user" != "$current_user" ]]; then
            # 如果普通用户试图修改别人，给出警告并修正
            print_error "普通用户只能修改自己的密码，已自动修正目标为: $current_user"
        fi
        target_user="$current_user"
    fi

    # 3. 检查用户是否存在
    if ! id "$target_user" &>/dev/null; then
        print_error "用户不存在: $target_user"
        return 1
    fi

    # 4. 提示信息
    if [[ "$target_user" == "$(whoami)" ]]; then
        print_box_info -s star -m "修改 [当前用户 ($target_user)] 的登录密码"
    else
        print_box_info -s star -m "修改 [指定用户 ($target_user)] 的登录密码"
    fi

    ui_warn "请输入新密码（输入过程不会显示，输入完毕按回车）"

    # 5. 执行修改
    # 注意：passwd 命令交互性较强
    if is_root; then
        # root 修改别人不需要知道旧密码
        passwd "$target_user"
    else
        # 普通用户修改自己需要先输入旧密码
        passwd
    fi

    # 捕获 passwd 的返回值 ($?)
    if [[ $? -eq 0 ]]; then
        print_box_success -s finish -m "修改 [指定用户 ($target_user)] 的登录密码"
        return 0
    else
        print_error "密码修改失败或已取消"
        return 1
    fi
}
