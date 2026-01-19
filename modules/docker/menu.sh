#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - Docker 工具模块入口
#
# @文件路径: /modules/docker/menu.sh
# @功能描述: 卸载 docker
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2026-01-08
# ==============================================================================

source "${BASE_DIR}/modules/docker/install.sh"
source "${BASE_DIR}/modules/docker/uninstall.sh"

# ------------------------------------------------------------------------------
# 函数名: menu_install_docker
# 功能:   安装 docker 前置
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   menu_install_docker
# ------------------------------------------------------------------------------
menu_install_docker() {
    if ! check_root; then
        return
    fi

    install_docker_logic
}

# ------------------------------------------------------------------------------
# 函数名: menu_uninstall_docker
# 功能:   卸载 docker 前置
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   menu_uninstall_docker
# ------------------------------------------------------------------------------
menu_uninstall_docker() {
    if ! check_root; then
        return
    fi

    print_box_info -s star -m "卸载前的最后确认..."

    print_warn -m " 注意: 卸载 Docker 环境 (包含: Docker 所有数据 [镜像, 容器, 卷])";

    if ! read_confirm; then
        return 1
    fi

    uninstall_docker_logic
}

# ------------------------------------------------------------------------------
# 函数名: docker_menu
# 功能:   Docker 模块菜单
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   docker_menu
# ------------------------------------------------------------------------------
docker_menu() {
    while true; do

        print_clear

        print_box_header "${ICON_DOCKER}$(print_spaces 1)Docker 管理"

        print_line
        print_echo "${BOLD_YELLOW}当前 Docker 环境: ${NC}$(get_docker_status_text)"

        print_line
        print_menu_item -r 1 -p 0 -i 1 -m "$(print_spaces 1)安装更新环境" -I star
        print_menu_item_done
        print_menu_item -r 2 -p 0 -i 2 -m "$(print_spaces 1)${BOLD_GREY}查看全局状态${NC}"
        print_menu_item_done

        print_line
        print_menu_item -r 3 -p 0 -i 3 -m "$(print_spaces 1)${BOLD_GREY}容器管理${NC}"
        print_menu_item -r 4 -p 0 -i 4 -m "$(print_spaces 1)${BOLD_GREY}镜像管理${NC}"
        print_menu_item -r 5 -p 0 -i 5 -m "$(print_spaces 1)${BOLD_GREY}网络管理${NC}"
        print_menu_item -r 6 -p 0 -i 6 -m "$(print_spaces 1)${BOLD_GREY}卷管理${NC}"
        print_menu_item_done

        print_line
        print_menu_item -r 7 -p 0 -i 7 -m "$(print_spaces 1)${BOLD_GREY}更换源${NC}"
        print_menu_item_done
        print_menu_item -r 8 -p 0 -i 8 -m "$(print_spaces 1)${BOLD_GREY}编辑 daemon.json${NC}"
        print_menu_item_done

        print_line
        print_menu_item -r 20 -p 0 -i 20 -m "卸载 Docker"
        print_menu_item_done

        print_menu_go_level

        choice=$(read_choice)

        case "$choice" in
            1)
                print_clear
                menu_install_docker
                print_wait_enter
                ;;
            20)
                print_clear
                if menu_uninstall_docker; then
                    print_wait_enter
                fi
                ;;

            99)
                :
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
