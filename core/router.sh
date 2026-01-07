#!/usr/bin/env bash
# 指定使用 bash 解释器执行本文件

# ============================================================
# VpsScriptKit - 主路由分发模块（最小可运行版）
#
# 职责说明：
# 1. 接收用户在主菜单中的输入
# 2. 根据输入值分发到对应模块
# 3. 统一处理非法输入
# 4. 占位模块支持，避免报错
# ============================================================

# ------------------------------
# 引入依赖模块
# ------------------------------

# 引入 UI 库，用于输出提示信息
source "${BASE_DIR}/lib/ui.sh"

# ------------------------------
# 主菜单路由函数
# ------------------------------

router_main() {
  # 参数 1：用户输入的主菜单选项
  local choice="$1"

  # 使用 case 语句对用户输入进行分发
  case "$choice" in

    1)
      # 用户输入 1 → 系统工具模块
      source "${BASE_DIR}/modules/system/menu.sh"
      # 加载系统工具模块入口文件
      system_entry
      # 调用系统工具模块入口函数
      ;;

    2)
      # 用户输入 2 → 基础工具模块占位
      source "${BASE_DIR}/modules/basic/entry.sh"
      # 加载占位模块文件
      module_entry
      # 调用占位模块入口函数
      ;;

    3)
      # 用户输入 3 → 进阶工具模块占位
      source "${BASE_DIR}/modules/advanced/entry.sh"
      # 加载占位模块文件
      module_entry
      # 调用占位模块入口函数
      ;;

    4)
      # 用户输入 4 → Docker 管理模块占位
      source "${BASE_DIR}/modules/docker/entry.sh"
      # 加载占位模块文件
      docker_entry
      # 调用占位模块入口函数
      ;;

    8)
      # 用户输入 8 → 测试脚本合集模块占位
      source "${BASE_DIR}/modules/test/menu.sh"
      test_menu
      ;;

    9)
      # 用户输入 9 → 节点搭建脚本模块占位
      source "${BASE_DIR}/modules/node/entry.sh"
      # 加载占位模块文件
      node_entry
      # 调用占位模块入口函数
      ;;

    99)
      # 用户输入 99 → 脚本工具模块占位
      source "${BASE_DIR}/modules/system/vsk_script/menu.sh"
      vsk_script_menu
      ;;

    0)
      # 用户输入 0 → 退出程序
      # ui clear
      
      # ui line
      # echo -e "${BOLD_GREEN}感谢使用 VpsScriptKit，再见！${LIGHT_WHITE}"
      # ui line
      ui_exit

      # sleep 1

      # ui clear
      
      # exit 0
      ;;

    *)
      ui error "无效选项，请输入菜单中存在的数字"
      sleep 1
      ;;
  esac
}

# ------------------------------
# 路由入口封装函数
# ------------------------------

router_dispatch() {
  # 参数 1：用户输入
  local input="$1"

  # 调用主菜单路由函数进行分发
  router_main "$input"
}
