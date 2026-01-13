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

    case "$choice" in
        1)
            # 系统工具模块
            if [[ -f "${BASE_DIR}/modules/system/menu.sh" ]]; then
                source "${BASE_DIR}/modules/system/menu.sh"
                system_menu
            else
                ui_error "模块文件丢失: modules/system/menu.sh"
                sleep 1
            fi
            ;;
        2)
            # 基础工具模块
            if [[ -f "${BASE_DIR}/modules/basic/menu.sh" ]]; then
                source "${BASE_DIR}/modules/basic/menu.sh"
                # 假设基础模块入口函数名为 basic_menu 或 module_entry
                basic_menu 
            fi
            ;;
        3)
            # 进阶工具模块
            if [[ -f "${BASE_DIR}/modules/advanced/entry.sh" ]]; then
                source "${BASE_DIR}/modules/advanced/entry.sh"
                module_entry
            fi
            ;;
        4)
            # Docker 管理模块
            if [[ -f "${BASE_DIR}/modules/docker/menu.sh" ]]; then
                source "${BASE_DIR}/modules/docker/menu.sh"
                docker_menu
            else
                ui_error "模块文件丢失: modules/docker/menu.sh"
                sleep 1
            fi
            ;;
        8)
            # 测试脚本合集
            if [[ -f "${BASE_DIR}/modules/test/menu.sh" ]]; then
                source "${BASE_DIR}/modules/test/menu.sh"
                test_menu
            else
                ui_error "模块文件丢失: modules/test/menu.sh"
                sleep 1
            fi
            ;;
        9)
            # 节点搭建脚本
            if [[ -f "${BASE_DIR}/modules/node/menu.sh" ]]; then
                source "${BASE_DIR}/modules/node/menu.sh"
                node_menu
            else
                ui_error "模块文件丢失: modules/node/menu.sh"
                sleep 1
            fi
            ;;
		99)
			# 脚本自管理
			if [[ -f "${BASE_DIR}/modules/system/maintain/menu.sh" ]]; then
                source "${BASE_DIR}/modules/system/maintain/menu.sh"
                maintain_menu
            else
                ui_error "模块文件丢失: modules/system/maintain/menu.sh"
                sleep 1
            fi
			;;	
		0)
			ui_exit
			;;
        *)
            ui error "无效选项，请输入菜单中存在的数字"
      		sleep 1
            ;;
    esac
}