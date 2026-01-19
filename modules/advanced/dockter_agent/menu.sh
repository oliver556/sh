#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - DockTer Agent 脚本选择
#
# @文件路径: modules/advanced/dockter_agent/menu.sh
# @功能描述: DockTer Agent 脚本选择导航页
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-15
# ==============================================================================

# ******************************************************************************
# 基础路径与环境定义
# ******************************************************************************
# shellcheck disable=SC1091
source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent.sh"
source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_binary.sh"
source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_unraid.sh"
source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_docker.sh"
# ------------------------------------------------------------------------------
# 函数名: dockter_agent_menu
# 功能:   进阶工具导航页
# 
# 参数:
#   无
# 
# 返回值:
#   无
# 
# 示例:
#   dockter_agent_menu
# ------------------------------------------------------------------------------
dockter_agent_menu() {
  while true; do
        print_clear

        print_box_header "${ICON_MAINTAIN}$(ui_spaces 1)DpockTer Agent 选择"
      
        print_line
        print_menu_item -r 1 -s 2  -p 0 -i 1 -m "智能安装 (自动检测)" -I star
        print_menu_item_done

        print_line
        print_menu_item -r 2 -s 2 -p 0 -i 2 -m "Linux 二进制安装 (Binary)"
        print_menu_item_done

        print_line
        print_menu_item -r 3 -s 2 -p 0 -i 3 -m "Unraid 专用安装"
        print_menu_item_done

        print_line
        print_menu_item -r 4 -s 2 -p 0 -i 4 -m "Docker 容器安装"
        print_menu_item_done

        print_menu_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                print_clear
                # source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent.sh"
                install_dockter_agent
                print_wait_enter
                ;;
            2)
                print_clear
                # source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_binary.sh"
                install_dockter_agent_binary
                print_wait_enter
                ;;
            3)
                print_clear
                # source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_unraid.sh"
                install_dockter_agent_unraid
                print_wait_enter
                ;;
            4)
                print_clear
                # source "${BASE_DIR}/modules/advanced/dockter_agent/install_dockter_agent_docker.sh"
                install_dockter_agent_docker
                print_wait_enter
                ;;
            0)
                return
            ;;
            *)
                print_error -m "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}