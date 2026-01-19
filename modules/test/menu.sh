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
    while true; do

        print_clear

        print_box_header "${ICON_TEST}$(ui_spaces 1)测试脚本工具"

        print_line
        print_menu_item -r 1 -p 0 -i 1 -s 2 -m "IP 质量测试 ${BOLD_GREY}(https://github.com/xykt/IPQuality)${NC}"
        print_menu_item_done

        print_menu_item -r 2 -p 0 -i 2 -s 2 -m "网络质量测试"
        # print_menu_item -r 3 -p 0 -i 3 -s 2 -m "回程路由"
        print_menu_item_done

        print_line
        print_menu_item -r 31 -p 0 -i 31 -m "bench 性能测试"
        print_menu_item -r 32 -p 0 -i 32 -m "spiritysdx 融合怪测评"
        print_menu_item_done

        print_line
        print_menu_item -r 91 -p 0 -i 91 -m "Node Quality 综合脚本 (Yabs + IP质量 + 网络质量 + 融合怪的部分功能)"
        print_menu_item_done

        print_menu_go_level

        choice=$(ui_read_choice)

        case "$choice" in
            1)
                print_clear
                print_step "正在运行 IP 质量检测..."
                print_blank
                bash <(curl -sL https://Check.Place) -I
                print_wait_enter
                ;;

            2)
                print_clear
                print_step "正在运行 NetQuality 网络质量检测..."
                print_blank
                bash <(curl -sL https://Check.Place) -N
                print_wait_enter
                ;;

            31)
                print_clear
                print_step "正在运行 bench 性能测试..."
                print_blank
                curl -Lso- bench.sh | bash
                print_wait_enter
                ;;

            32)
                ul clear
                print_step "正在运行 spiritysdx 融合怪测评..."
                curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
                print_blank
                print_wait_enter
                ;;

            91)
                print_clear
                # sudo apt-get install virt-what
                bash <(curl -L https://run.NodeQuality.com)
                print_blank

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

