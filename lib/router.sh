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
            # 系统工具
            # shellcheck disable=SC1091
            source "${BASE_DIR}/modules/system/menu.sh"
            system_menu
            ;;
        2)
            # 常用工具箱 (Tools Manager)  <-- 这里放 Tmux、Docker、Zsh 等需要“交互/管理”的
            # shellcheck disable=SC1091
            source "${BASE_DIR}/modules/basic/menu.sh"
            basic_menu 
            ;;
        3)
            # 软件安装中心(Software Installer) <-- 这里放 curl, wget, git, vim 的纯安装/卸载
            # 进阶工具模块
            # shellcheck disable=SC1091
            source "${BASE_DIR}/modules/advanced/menu.sh"
            advanced_menu
            ;;
        4)
            # Docker 管理模块
            source "${BASE_DIR}/modules/docker/menu.sh"
            docker_menu
            ;;
        8)
            # 测试脚本合集
            source "${BASE_DIR}/modules/test/menu.sh"
            test_menu
            ;;
        9)
            # 节点搭建脚本
            source "${BASE_DIR}/modules/node/menu.sh"
            node_menu
            ;;
		99)
			# 脚本自管理
            source "${BASE_DIR}/modules/system/maintain/menu.sh"
            maintain_menu
			;;	
		0)
			print_exit
			;;
        *)
            print_error -m "无效选项，请输入菜单中存在的数字"
      		sleep 1
            ;;
    esac
}