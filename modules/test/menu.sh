#!/usr/bin/env bash

# ============================================================
# VpsScriptKit - 测试脚本模块入口
# @名称:         test/menu.sh
# @职责:
# - 整个各种测试脚本
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2026-01-05
# @修改日期:     2025-01-05
#
# @许可证:       MIT
# ============================================================

test_menu() {
  # 使用无限循环保证模块不会意外退出
  while true; do

    ui clear

    ui print page_header_full "🧪  测试脚本工具"

    ui line
    ui_menu_item 1 0 1 "IP 质量测试 ${BOLD_GREY}(https://github.com/xykt/IPQuality)${RESET}"
    ui_menu_done

    ui_menu_item 2 0 2 "网络质量测试"
    # ui_menu_item 3 0 3 "回程路由"
    ui_menu_done

    ui line
    ui_menu_item 4 0 31 "bench 性能测试"
    ui_menu_item 5 0 32 "spiritysdx 融合怪测评"
    ui_menu_done

    ui line
    ui_menu_item 9 0 91 "Node Quality 综合脚本 (Yabs + IP质量 + 网络质量 + 融合怪的部分功能)"
    ui_menu_done

    # 底部返回
    ui_go_level 0

    # 读取用户输入
    choice=$(ui_read_choice)

    # 根据用户输入执行不同操作
    case "$choice" in
      1)
        # 选项 1: IP 质量测试
        ui clear
        ui echo "🚀 正在运行 IP 质量检测..."
        ui blank
        bash <(curl -sL https://Check.Place) -I
        ui_wait_enter
      ;;

      2)
        ui clear
        ui echo "🚀 正在运行 NetQuality 网络质量检测..."
        ui blank
        bash <(curl -sL https://Check.Place) -N
        ui_wait_enter
      ;;

      31)
        ui clear
        ui echo "🚀 正在运行 bench 性能测试..."
        ui blank
        curl -Lso- bench.sh | bash
        ui_wait_enter
      ;;

      32)
        ul clear
        ui echo "🚀 正在运行 spiritysdx 融合怪测评..."
        curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
        ui blank
        ui_wait_enter
      ;;

      91)
        ui clear
        # sudo apt-get install virt-what
        # bash <(curl -sL https://run.NodeQuality.com)
        bash <(curl -L https://run.NodeQuality.com)
        ui blank

        ui_wait_enter
      ;;

      0)
        # 选项 0: 返回主菜单
        return
        # 使用 return 而不是 exit，返回到上级调用者（router）
      ;;

      *)
        # 处理非法输入
        ui_error "无效选项，请重新输入"
        # 短暂暂停，避免立刻刷新
        sleep 1
      ;;
    esac

  done

}

