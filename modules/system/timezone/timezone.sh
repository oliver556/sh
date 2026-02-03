#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 系统时区调整模块
#
# @文件路径: modules/system/timezone.sh
# @功能描述: 查看当前时间状态、切换系统时区 (兼容 Alpine/Systemd)
#
# @作者: Jamison
# @版本: 0.1.0
# ==============================================================================

# 加载依赖
# shellcheck disable=SC1091
source "${BASE_DIR}/lib/print.sh"
# 假设 check_root 定义在 utils.sh 或 main.sh 中，这里直接调用即可

# ------------------------------------------------------------------------------
# 函数名: _get_current_timezone
# 功能:   获取当前系统时区字符串
# ------------------------------------------------------------------------------
_get_current_timezone() {
    if command -v timedatectl &>/dev/null; then
        timedatectl show --property=Timezone --value 2>/dev/null
    elif [ -f /etc/timezone ]; then
        cat /etc/timezone
    elif [ -h /etc/localtime ]; then
        readlink /etc/localtime | awk -F'/zoneinfo/' '{print $2}'
    else
        echo "Unknown"
    fi
}

# ------------------------------------------------------------------------------
# 函数名: _draw_time_status
# 功能:   绘制当前时间和时区状态面板
# ------------------------------------------------------------------------------
_draw_time_status() {
    local current_tz
    current_tz=$(_get_current_timezone)
    
    local current_time
    current_time=$(date +"%Y-%m-%d %H:%M:%S")
    
    local utc_time
    utc_time=$(date -u +"%Y-%m-%d %H:%M:%S")

    # 使用状态栏组件渲染
    # 第一行: 时区 和 UTC时间
    print_status_item -l "当前时区:" -v "${GREEN}${current_tz}${NC}" -w 12 -W 24
    print_status_item -l "UTC时间:" -v "${WHITE}${utc_time}${NC}" -w 10
    print_status_done
    
    # 第二行: 本地时间
    print_status_item -l "本机时间:" -v "${BOLD_CYAN}${current_time}${NC}" -w 12
    print_status_done
}

# ------------------------------------------------------------------------------
# 函数名: set_timezone
# 功能:   执行时区修改逻辑 (核心功能)
# 参数:   $1 (Target Timezone String)
# ------------------------------------------------------------------------------
set_timezone() {
    local target_tz="$1"
    
    # 1. 权限检查
    check_root || return

    print_clear
    print_box_info -m "正在设置时区为: ${BOLD_YELLOW}${target_tz}${NC}" -s start

    # 2. 执行修改 (兼容逻辑)
    if grep -q 'Alpine' /etc/issue; then
        # Alpine Linux 处理逻辑
        print_step -m "检测到 Alpine Linux，正在安装 tzdata..."
        if command -v apk &>/dev/null; then
             apk add --no-cache tzdata >/dev/null 2>&1
        fi
        
        print_step -m "复制时区文件..."
        if [ -f "/usr/share/zoneinfo/${target_tz}" ]; then
            cp "/usr/share/zoneinfo/${target_tz}" /etc/localtime
            echo "${target_tz}" > /etc/timezone
            
            print_step -m "同步硬件时钟..."
            hwclock --systohc
        else
            print_box_error -m "未找到时区文件: ${target_tz}"
            print_wait_enter
            return
        fi
    else
        # 标准 Linux (Systemd) 处理逻辑
        print_step -m "使用 timedatectl 设置时区..."
        if timedatectl set-timezone "${target_tz}"; then
            : # 成功不输出
        else
            # 兜底：如果 timedatectl 失败 (例如 docker 容器内)，尝试软链接
            ln -sf "/usr/share/zoneinfo/${target_tz}" /etc/localtime
        fi
    fi

    # 3. 成功反馈
    print_box_success -m "时区设置成功！"
    
    # 强制刷新一下显示给用户看
    local new_time
    new_time=$(date +"%Y-%m-%d %H:%M:%S")
    print_key_value -k "当前时间" -v "${new_time}"
    
    return 0
}

# ------------------------------------------------------------------------------
# 函数名: timezone_menu
# 功能:   时区选择主菜单
# ------------------------------------------------------------------------------
timezone_menu() {
    while true; do
        print_clear
        print_box_header "系统时区调整 (Timezone Settings)"
        
        print_line
        _draw_time_status
        print_line

        # --- 亚洲区域 ---
        print_step -m "亚洲 (Asia)"
        print_menu_item -r 1 -p 0 -i 1 -m "中国上海"
        print_menu_item -r 1 -p 18 -i 2 -m "中国香港"
        print_menu_item -r 2 -p 0 -i 3 -m "日本东京"
        print_menu_item -r 2 -p 18 -i 4 -m "韩国首尔"
        print_menu_item -r 5 -p 0 -i 5 -m "新加坡"
        print_menu_item -r 5 -p 20 -i 6 -m "印度加尔各答"
        print_menu_item -r 7 -p 0 -i 7 -m "阿联酋迪拜"
        print_menu_item -r 7 -p 16 -i 9 -m "泰国曼谷"
        print_menu_item_done
        print_line -c "─" -C "${GREY}"

        # --- 澳洲区域 ---
        print_step -m "澳洲 (Australia)"
        print_menu_item -r 8 -p 0 -i 8 -m "澳大利亚悉尼"
        print_menu_item_done
        print_line -c "─" -C "${GREY}"

        # --- 欧洲区域 ---
        print_step -m "欧洲 (Europe)"
        print_menu_item -r 11 -p 0 -i 11 -m "英国伦敦"
        print_menu_item -r 11 -p 16 -i 12 -m "法国巴黎"
        print_menu_item -r 13 -p 0 -i 13 -m "德国柏林"
        print_menu_item -r 13 -p 16 -i 14 -m "莫斯科"
        print_menu_item -r 15 -p 0 -i 15 -m "荷兰阿姆斯特丹" # Utrecht 较少用，改用标准 Amsterdam
        print_menu_item -r 15 -p 10 -i 16 -m "西班牙马德里"
        print_menu_item_done
        print_line -c "─" -C "${GREY}"

        # --- 美洲区域 ---
        print_step -m "美洲 (Americas)"
        print_menu_item -r 21 -p 0 -i 21 -m "美国西部"
        print_menu_item -r 21 -p 16 -i 22 -m "美国东部"
        print_menu_item -r 23 -p 0 -i 23 -m "加拿大温哥华"
        print_menu_item -r 23 -p 12 -i 24 -m "墨西哥"
        print_menu_item -r 25 -p 0 -i 25 -m "巴西圣保罗"
        print_menu_item -r 25 -p 14 -i 26 -m "阿根廷"
        print_menu_item_done
        print_line -c "─" -C "${GREY}"

        # --- 全球标准 ---
        print_menu_item -r 31 -p 0 -i 31 -m "UTC 全球标准时间" -I star
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            # 亚洲
            1) if set_timezone "Asia/Shanghai"; then print_wait_enter; fi ;;
            2) if set_timezone "Asia/Hong_Kong"; then print_wait_enter; fi ;;
            3) if set_timezone "Asia/Tokyo"; then print_wait_enter; fi ;;
            4) if set_timezone "Asia/Seoul"; then print_wait_enter; fi ;;
            5) if set_timezone "Asia/Singapore"; then print_wait_enter; fi ;;
            6) if set_timezone "Asia/Kolkata"; then print_wait_enter; fi ;;
            7) if set_timezone "Asia/Dubai"; then print_wait_enter; fi ;;
            9) if set_timezone "Asia/Bangkok"; then print_wait_enter; fi ;;

            # 澳洲
            8) if set_timezone "Australia/Sydney"; then print_wait_enter; fi ;;
            
            # 欧洲
            11) if set_timezone "Europe/London"; then print_wait_enter; fi ;;
            12) if set_timezone "Europe/Paris"; then print_wait_enter; fi ;;
            13) if set_timezone "Europe/Berlin"; then print_wait_enter; fi ;;
            14) if set_timezone "Europe/Moscow"; then print_wait_enter; fi ;;
            15) if set_timezone "Europe/Amsterdam"; then print_wait_enter; fi ;;
            16) if set_timezone "Europe/Madrid"; then print_wait_enter; fi ;;
            
            # 美洲
            21) if set_timezone "America/Los_Angeles"; then print_wait_enter; fi ;;
            22) if set_timezone "America/New_York"; then print_wait_enter; fi ;;
            23) if set_timezone "America/Vancouver"; then print_wait_enter; fi ;;
            24) if set_timezone "America/Mexico_City"; then print_wait_enter; fi ;;
            25) if set_timezone "America/Sao_Paulo"; then print_wait_enter; fi ;;
            26) if set_timezone "America/Argentina/Buenos_Aires"; then print_wait_enter; fi ;;
            
            # UTC
            31) if set_timezone "UTC"; then print_wait_enter; fi ;;
            
            0) return ;;
            *) print_error -m "无效选项" ;;
        esac
    done
}