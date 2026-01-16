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
  # 确保为 root 用户执行，不是则提示，重新加载当前菜单界面
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
  ui clear

  # 确保为 root 用户执行，不是则提示，重新加载当前菜单界面
  if ! check_root; then
    return
  fi

  ui_box_info "开始卸载前的最后确认..."

  if ! ui_confirm " 注意: 确定卸载 Docker 环境吗？[包含: Docker 所有数据 (镜像, 容器, 卷)]"; then
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

    ui clear

    ui print page_header "☵$(ui_spaces 1)Docker 管理"

    ui line
    ui echo "${BOLD_YELLOW}当前 Docker 环境: ${RESET}$(get_docker_status_text)"

    ui line
    ui_menu_item 1 0 1 "$(ui_spaces 1)安装更新环境 ${BOLD_YELLOW}★${LIGHT_WHITE}"
    ui_menu_done
    ui_menu_item 1 0 2 "$(ui_spaces 1)${BOLD_GREY}查看全局状态${RESET}"
    ui_menu_done

    ui line
    ui_menu_item 2 0 3 "$(ui_spaces 1)${BOLD_GREY}容器管理${RESET}"
    ui_menu_done
    ui_menu_item 2 0 4 "$(ui_spaces 1)${BOLD_GREY}镜像管理${RESET}"
    ui_menu_done
    ui_menu_item 2 0 5 "$(ui_spaces 1)${BOLD_GREY}网络管理${RESET}"
    ui_menu_done
    ui_menu_item 2 0 6 "$(ui_spaces 1)${BOLD_GREY}卷管理${RESET}"
    ui_menu_done

    ui line
    ui_menu_item 3 0 7 "$(ui_spaces 1)${BOLD_GREY}更换源${RESET}"
    ui_menu_done
    ui_menu_item 2 0 8 "$(ui_spaces 1)${BOLD_GREY}编辑 daemon.json${RESET}"
    ui_menu_done

    ui line
    ui_menu_item 8 0 20 "卸载 Docker"
    ui_menu_done

    ui_go_level

    # 读取用户输入
    choice=$(ui_read_choice)

    # 根据用户输入执行不同操作
    case "$choice" in
      1)
        ui clear
        menu_install_docker
        ui_wait_enter
      ;;
      20)
        ui clear
        menu_uninstall_docker
        ui_wait_enter
      ;;

      99)
        :
      ;;

      0)
        # 选项 0: 返回主菜单
        return
        # 使用 return 而不是 exit，返回到上级调用者（router）
      ;;

      *)
        # 处理非法输入
        ui_warn_menu "无效选项，请重新输入..."
        # 短暂暂停，避免立刻刷新
        sleep 1
      ;;
    esac
  done
}
