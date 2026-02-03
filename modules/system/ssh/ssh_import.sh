#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - SSH 公钥导入工具

# @文件路径: modules/system/ssh/ssh_import.sh
# @功能描述: 
#
# @作者:    Jamison
# @版本:    1.0.0
# ==============================================================================

# 引入核心应用逻辑
# shellcheck disable=1091
source "${BASE_DIR}/modules/system/ssh/ssh_core.sh"

# ------------------------------------------------------------------------------
# 1. 手动导入
# ------------------------------------------------------------------------------
ssh_import_manual() {
    print_clear

    print_box_info -m "手动导入 SSH 公钥"
    
    print_info -m "请输入您的 SSH 公钥内容 (以 ssh-rsa / ssh-ed25519 开头):"
    local pub_key
    read -r -e pub_key

    if ssh_add_key "$pub_key"; then
        ssh_apply_policy
    fi
    return 0
}

# ------------------------------------------------------------------------------
# 2. GitHub 导入
# ------------------------------------------------------------------------------
ssh_import_github() {
    print_clear

    print_box_info -m "从 GitHub 导入公钥"
    
    print_info -m "此脚本将从 Github 拉取您的 SSH 公钥，并添加到 /root/.ssh/zuthorized_keys" 中

    print_blank

    print_info -m "操作前，请确保您已经在 Github 账户中添加了 SSH 公钥:"
    print_info -m "1. 登录 https://github.com/settings/keys"
    print_info -m "2. 点击 New SSH Key 或 Add SSH Key"
    print_info -m "3. Title 可随意填写 (例如: Home Laptop 2026)"
    print_info -m "4. 将本地公钥内容 (通常是 ~./ssh/id_rsa.pub 或 ~./ssh/id_ed25519.pub 的全部内容) 粘贴到 Key 字段"
    print_info -m "5. 点击 Add SSH Key 完成添加"
    print_blank
    print_info -m "添加完成后, Github 会公开提供您的所有公钥, 地址为:"
    print_info -m "https://github.com/<用户名>.keys"
    print_blank
    print_echo -n "${BOLD_CYAN}请输入 GitHub 用户名 (username, 不含@, 输入 0 返回): ${NC}"
    local username
    read -r username

    if [[ "$username" == "0" ]]; then
        return 1
    fi

    if [[ -z "$username" ]]; then
        print_error "用户名不能为空。"
        return
    fi

    local url="https://github.com/${username}.keys"

    print_line
    print_step -m "即将拉取地址: ${BOLD_WHITE}${url}${NC}"

    if ! read_confirm "确认导入?"; then
        return 0
    fi
    
    ssh_import_url_core "$url"
}

# ------------------------------------------------------------------------------
# 3. URL 导入 (入口)
# ------------------------------------------------------------------------------
ssh_import_url() {
    print_clear

    print_box_info -m "从 URL 导入公钥"
    
    print_echo -n "${BOLD_CYAN}请输入公钥 URL 地址: ${NC}"
    local url
    read -r url

    if [[ -z "$url" ]]; then
        print_error "URL 不能为空。"
        return 1
    fi

    ssh_import_url_core "$url"
}

# ------------------------------------------------------------------------------
# 4. URL 导入 (核心逻辑)
# ------------------------------------------------------------------------------
ssh_import_url_core() {
    local url="$1"
    print_step -m "正在从远程获取公钥..."
    print_info -m "地址: $url"

    local temp_file
    temp_file=$(mktemp)

    # 1. 下载失败检查
    if ! curl -fsSL --connect-timeout 10 "$url" -o "$temp_file"; then
        print_error -m "下载失败，请检查网络或 URL。"
        rm -f "$temp_file"
        return 1
    fi

    # 2. 空文件检查
    if [[ ! -s "$temp_file" ]]; then
        print_error -m "下载的文件为空。"
        rm -f "$temp_file"
        return 1
    fi

    # 统计有效公钥数量
    # grep -vUc "^#" 统计非注释行数
    local total_keys
    total_keys=$(grep -vEc "^\s*(#|$)" "$temp_file")

    if [[ "$total_keys" -eq 0 ]]; then
        print_error -m "未找到有效公钥数据。"
        rm -f "$temp_file"
        return 1
    fi

    print_info -m "获取成功，共发现 ${BOLD_WHITE}${total_keys}${NC} 个公钥。"

    # --- 模式选择 ---
    local import_mode="all"
    if [[ "$total_keys" -gt 1 ]]; then
        # 使用 -n 参数，read_confirm 正常从键盘读取
        if ! read_confirm -n -m "是否全部导入？ (选择 n 进入逐个筛选模式)"; then
            import_mode="select"
            print_blank
            print_step -m "进入筛选模式..."
        fi
    fi

    # 统计计数器
    local added_count=0
    local skipped_count=0
    local current_index=0

    # 临时文件用于计算指纹
    local single_key_temp
    single_key_temp=$(mktemp)

    # 逐行处理 (使用 FD 3 读取文件，防止吞掉标准输入)
    while IFS= read -u 3 -r line; do
        # 跳过空行和注释
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        ((current_index++))

        # 如果是筛选模式，进行交互询问
        if [[ "$import_mode" == "select" ]]; then
            print_blank
            print_line -c "-" -C "$BOLD_GREY"

            echo "$line" > "$single_key_temp"
            # ssh-keygen -lf 会输出: 256 SHA256:xxxxxx... (Type)
            local fingerprint
            fingerprint=$(ssh-keygen -lf "$single_key_temp" 2>/dev/null | awk '{print $2}')

            # 如果算不出来(比如格式不对)，就回退到显示部分内容
            if [[ -z "$fingerprint" ]]; then
                 local kbody
                 kbody=$(echo "$line" | awk '{print $2}')
                 fingerprint="...${kbody: -15}"
            fi

            # 提取类型 (ssh-rsa / ssh-ed25519)
            local ktype
            ktype=$(echo "$line" | awk '{print $1}')

            # 显示给用户对比
            echo -e "公钥 [${current_index}/${total_keys}]: ${BOLD_CYAN}${ktype}${NC}"
            echo -e "指纹: ${BOLD_YELLOW}${fingerprint}${NC} (请对比 GitHub 界面)"
            
            if ! read_confirm -n -m "导入此公钥?"; then
                print_echo "${DIM}➜ 已忽略${NC}"
                continue
            fi
        fi
        
        # 调用核心函数添加
        ssh_add_key "$line"
        local ret=$?
        
        if [[ $ret -eq 0 ]]; then
            ((added_count++))
        elif [[ $ret -eq 2 ]]; then
            ((skipped_count++))
        fi
    done 3< "$temp_file"

    rm -f "$temp_file" "$single_key_temp"

    # 场景 1: 有新公钥导入 -> 必须确保安全策略生效
    if [[ "$added_count" -gt 0 ]]; then
        print_box_success -s finish -m "处理完成: 新增 $added_count 条 (跳过 $skipped_count 条已存在/忽略)"
        ssh_apply_policy
        return 0
    
    # 场景 2: 全部都是旧公钥 (无需重复添加)
    elif [[ "$skipped_count" -gt 0 ]]; then
        print_warn -m "未导入新公钥 (检测到 $skipped_count 条均已存在或被忽略)。"
        
        # [智能判断] 检查系统当前是否已经安全
        if ssh_check_policy_status; then
            # 已经是安全模式 (PasswordAuth=no)，直接收工，不打扰用户
            print_success -m "系统已处于密钥登录模式，无需变更配置。"
            return 0
        else
            # 虽然公钥已存在，但密码登录还开着，必须关掉它！
            print_blank
            print_info -m "检测到当前仍允许密码登录，正在应用安全策略..."
            ssh_apply_policy
            return 0
        fi
        
    # 场景 3: 文件里没读到有效行
    else
        print_warn -m "未导入任何公钥。"
        return 1
    fi
}