#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - SSH 密钥对生成

# @文件路径: modules/system/ssh/ssh_keygen.sh
# @功能描述: 
#
# @作者:    Jamison
# @版本:    1.0.0
# ==============================================================================

# 引入核心应用逻辑
# shellcheck disable=1091
source "${BASE_DIR}/modules/system/ssh/ssh_core.sh"

ssh_enable_auto() {
    print_clear

    print_box_info -m "开启密钥模式 (自动部署)"

    # 使用自定义名称，避免覆盖系统默认的
    local key_name="vsk_sshkey"
    local key_path="$HOME/.ssh/${key_name}"
    local comment
    comment="vsk_gen_$(date +%Y%m%d)"
    
    # 检查是否已存在
    if [[ -f "$key_path" ]]; then
        print_warn -m "检测到已存在密钥对: $key_path"
        if ! read_confirm "是否覆盖生成? (原密钥将丢失)"; then
            return
        fi
        rm -f "$key_path" "$key_path.pub"
    fi

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    print_step -m "正在生成 Ed25519 密钥对..."

    print_blank
    
    # -N "" 表示空密码，-f 指定路径，-C 备注
    if ssh-keygen -t ed25519 -C "$comment" -f "$key_path" -N ""; then
        print_blank
        print_success -m "密钥生成成功！"
        
        # 读取内容，传给 ssh_add_key
        local pub_content
        pub_content=$(cat "${key_path}.pub")
        
        # 添加公钥
        if ssh_add_key "$pub_content"; then
            
            # 获取本机 IP 用于提示文件名
            local ip
            if declare -f net_get_ipv4 > /dev/null; then
                ip=$(net_get_ipv4)
            else
                ip="server"
            fi
        
            print_blank
            print_box_warn -m "【私钥下载提示】"
            print_info -m "请立即复制下方私钥内容，保存为文件 (例如: ${ip}_key.pem)"
            print_info -m "您需要使用此私钥文件来登录服务器。"
            
            print_line -c "-"
            cat "$key_path"
            print_line -c "-"
            
            ssh_apply_policy
        fi

        return 0
    else
        print_error -m "密钥生成失败，请检查磁盘空间或权限。"
        return 1
    fi
}