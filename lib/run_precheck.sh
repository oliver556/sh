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
    print_blank
    print_info -I "$ICON_GEAR" -C "$BOLD_BLUE" "正在进行环境预检..."
    print_blank

    print_echo -n "$(print_spaces 2)检查 Root 权限... "
    if check_root; then
        print_echo "${GREEN}${ICON_OK} Pass${NC}"
    else
        print_echo "${RED}${ICON_FAIL} Fail (需 Root)${NC}"
        return 1
    fi

    # 2. 检测操作系统
    print_echo -n "$(print_spaces 2)检查操作系统...  "
    if check_supported_os; then
        print_echo "${GREEN}${ICON_OK} Pass${NC}"
    else
        print_echo "${RED}${ICON_FAIL} Fail (不支持)${NC}"
        return 1
    fi

    print_echo -n "$(print_spaces 2)检查网络连通...  "
    if has_internet; then
         print_echo "${GREEN}${ICON_OK} Pass${NC}"
    else
         print_echo "${YELLOW}${ICON_WARNING} Warning (离线?)${NC}"
         # 网络不通未必致死，可以不 return
    fi

    sleep 1
}