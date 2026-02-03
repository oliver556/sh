#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 查看与编辑 SSH 密钥

# @文件路径: modules/system/ssh/ssh_view.sh
# @功能描述: 
#
# @作者:    Jamison
# @版本:    1.0.0
# ==============================================================================

ssh_view_keys() {
    print_clear

    print_box_header "查看本机密钥信息"

    local auth_file="$HOME/.ssh/authorized_keys"
    
    if [[ -f "$auth_file" ]]; then
        print_box_header_tip -h "已授权的公钥 (authorized_keys)"
        print_line -c "-"
        cat "$auth_file"
        print_line -c "-"
    else
        print_warn -m "未找到 authorized_keys 文件。"
    fi
    
    # 尝试查找常见私钥
    local key_found=false
    for key_type in id_ed25519 id_rsa id_ecdsa; do
        if [[ -f "$HOME/.ssh/$key_type" ]]; then
            print_blank
            print_box_header_tip -h "发现私钥: $key_type"
            print_line -c "-"
            cat "$HOME/.ssh/$key_type"
            print_line -c "-"
            key_found=true
        fi
    done
    
    if [[ "$key_found" == "false" ]]; then
        print_info -m "未发现默认路径下的私钥文件。"
    fi
    
    print_wait_enter
}

ssh_edit_authorized_keys() {
    local auth_file="$HOME/.ssh/authorized_keys"
    
    if ! has_cmd "nano"; then
        pkg_install "nano"
    fi
    
    print_info -m "正在打开编辑器..."
    nano "$auth_file"
    
    print_success -m "编辑结束。"
}