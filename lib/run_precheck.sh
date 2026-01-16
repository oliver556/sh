#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 环境预检测
#
# @文件路径: lib/run_precheck.sh
# @功能描述: 负责 “运行” (环境预检测)
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-16
# ==============================================================================

run_precheck() {
    echo -e "${BOLD_BLUE}环境预检...${NC}"

    # 检测是否 root
    echo -n "检查 root 权限..."
    if check_root; then
        echo -e "[${GREEN}${ICON_OK}${NC}]"
    else
        echo -e "[${RED}${ICON_FAIL}${NC}]"
        exit 1
    fi

    # 检测操作系统
    echo -n "检查操作系统..."

    if check_supported_os; then
        echo -e "[${GREEN}${ICON_OK}${NC}]"
    else
        echo -e "[${RED}${ICON_FAIL}${NC}]"
        exit 1
    fi

    sleep 2
}