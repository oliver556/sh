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

        ui print page_header "⚒$(ui_spaces 1)DpockTer Agent 选择"
      
        ui line
        ui_menu_item 1 0 1 "$(ui_spaces 1)智能安装 (自动检测) ${BOLD_YELLOW}★${BOLD_WHITE}"
        ui_menu_done

        ui line
        ui_menu_item 2 0 2 "$(ui_spaces 1)Linux 二进制安装 (Binary)"
        ui_menu_done

        ui line
        ui_menu_item 3 0 3 "$(ui_spaces 1)Unraid 专用安装"
        ui_menu_done

        ui line
        ui_menu_item 4 0 4 "$(ui_spaces 1)Docker 容器安装"
        ui_menu_done

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
                ui_warn_menu "无效选项，请重新输入..."
                sleep 1
            ;;
        esac
    done
}