#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 主路由分发模块
# 
# @文件路径: lib/router.sh
# @功能描述: 接收主菜单输入，加载对应子模块并执行入口函数
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-09
# ==============================================================================

# ------------------------------------------------------------------------------
# 函数名: router_main
# 功能:   根据主菜单选择分发到子模块
# 参数:
#   $1 (number): 用户选择的数字 (1, 2, 3...) (必填)
#
# 返回值:
#   执行对应的函数功能
#
# 示例:
#   router_main "$choice"
# ------------------------------------------------------------------------------
router_main() {
    local choice="$1"
    local module_script=""
    local entry_function=""

    case "$choice" in
        1)
            # 系统工具
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/system/menu.sh"
            entry_function="system_menu"
            ;;
        2)
            # 常用工具箱 (Tools Manager)
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/basic/menu.sh"
            entry_function="basic_menu" 
            ;;
        3)
            # 进阶工具模块
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/advanced/menu.sh"
            entry_function="advanced_menu"
            ;;
        4)
            # Docker 管理模块
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/docker/menu.sh"
            entry_function="docker_menu"
            ;;
        8)
            # 测试脚本合集
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/test/menu.sh"
            entry_function="test_menu"
            ;;
        9)
            # 节点搭建脚本
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/node/menu.sh"
            entry_function="node_menu"
            ;;
		99)
			# 脚本自管理
            # shellcheck disable=SC1091
            module_script="${BASE_DIR}/modules/system/maintain/menu.sh"
            entry_function="maintain_menu"
			;;	
		0)
			print_exit
			;;
        *)
            print_error -m "无效选项，请输入菜单中存在的数字"
      		sleep 1
            ;;
    esac

    # 统一加载与执行逻辑 (DRY 原则)
    if [[ -f "$module_script" ]]; then
        # shellcheck disable=SC1090
        source "$module_script"
        
        if declare -f "$entry_function" > /dev/null; then
            "$entry_function"
        else
            print_error "模块入口函数丢失: $entry_function"
        fi
    else
        print_error "模块文件丢失: $module_script"
    fi
}