#!/usr/bin/env bash

### ============================================================
# VpsScriptKit - 能力检测工具 - 函数库
# @名称:         validate.sh
# @职责:
# 1. 提供通用的“能力检测”函数
# 2. 判断命令 / 文件 / 系统特性是否可用
#
# 设计原则：
# - 只判断，不输出 UI
# - 只返回状态码（0 成功 / 1 失败）
# - 不 exit，不中断程序
# - 不依赖 ui.sh
# @作者:         Jamison
# @版本:         0.1.0
# @创建日期:     2025-12-31
# @修改日期:     2025-01-04
#
# @许可证:       MIT
### ============================================================

# ------------------------------
# 基础：命令是否存在
# ------------------------------

validate_cmd_exists() {
  # 判断单个命令是否存在于 PATH 中
  #
  # 参数：
  #   $1 - 命令名（如 ip / free / curl）
  #
  # 返回：
  #   0 - 命令存在
  #   1 - 命令不存在

  local cmd="$1"
  # 将第一个参数保存为本地变量

  command -v "$cmd" >/dev/null 2>&1
  # 使用 command -v 检查命令是否存在
  # 输出重定向到 /dev/null，避免任何输出

  return $?
  # 返回 command -v 的退出码
}

# ------------------------------
# 批量判断多个命令是否存在
# ------------------------------

validate_cmds_exist() {
  # 判断多个命令是否全部存在
  #
  # 参数：
  #   $@ - 命令列表
  #
  # 返回：
  #   0 - 全部存在
  #   1 - 任意一个不存在

  local cmd
  # 定义循环用变量

  for cmd in "$@"; do
    # 遍历所有传入的命令

    if ! validate_cmd_exists "$cmd"; then
      # 如果某个命令不存在

      return 1
      # 立即返回失败
    fi
  done

  return 0
  # 所有命令均存在
}

# ------------------------------
# 文件 / 目录存在性判断
# ------------------------------

validate_file_exists() {
  # 判断文件是否存在
  #
  # 参数：
  #   $1 - 文件路径
  #
  # 返回：
  #   0 - 文件存在
  #   1 - 文件不存在

  local file="$1"
  # 保存文件路径

  [[ -f "$file" ]]
  # -f 判断是否为普通文件

  return $?
  # 返回判断结果
}

validate_dir_exists() {
  # 判断目录是否存在
  #
  # 参数：
  #   $1 - 目录路径
  #
  # 返回：
  #   0 - 目录存在
  #   1 - 目录不存在

  local dir="$1"
  # 保存目录路径

  [[ -d "$dir" ]]
  # -d 判断是否为目录

  return $?
}

# ------------------------------
# Linux 特性判断
# ------------------------------

validate_proc_available() {
  # 判断 /proc 是否可用
  #
  # /proc 是获取 CPU / 内存 / 运行时间的基础
  #
  # 返回：
  #   0 - /proc 可用
  #   1 - 不可用

  [[ -d /proc ]]
  # 判断 /proc 目录是否存在

  return $?
}

validate_sysfs_available() {
  # 判断 /sys 是否可用
  #
  # /sys 常用于硬件信息
  #
  # 返回：
  #   0 - /sys 可用
  #   1 - 不可用

  [[ -d /sys ]]
  # 判断 /sys 目录是否存在

  return $?
}

# ------------------------------
# 网络相关能力判断
# ------------------------------

validate_ip_cmd() {
  # 判断系统是否具备网络接口查询能力
  #
  # 优先顺序：
  #   1. ip
  #   2. ifconfig
  #
  # 返回：
  #   0 - 至少存在一种
  #   1 - 均不存在

  if validate_cmd_exists "ip"; then
    # 如果 ip 命令存在

    return 0
  fi

  if validate_cmd_exists "ifconfig"; then
    # 如果 ip 不存在，但 ifconfig 存在

    return 0
  fi

  return 1
  # 两种命令都不存在
}

validate_ping_cmd() {
  # 判断是否存在 ping 命令
  #
  # 返回：
  #   0 - ping 存在
  #   1 - ping 不存在

  validate_cmd_exists "ping"
  # 直接复用命令检测
}

# ------------------------------
# 外部请求能力判断（供 network.sh 使用）
# ------------------------------

validate_http_client() {
  # 判断是否存在 HTTP 客户端工具
  #
  # 支持：
  #   curl
  #   wget
  #
  # 返回：
  #   0 - 至少存在一种
  #   1 - 均不存在

  if validate_cmd_exists "curl"; then
    # curl 存在

    return 0
  fi

  if validate_cmd_exists "wget"; then
    # wget 存在

    return 0
  fi

  return 1
  # 两者均不存在
}

# ------------------------------
# 通用断言工具（不输出，不退出）
# ------------------------------

validate_or_warn() {
  # 执行某个校验函数，并返回结果
  #
  # 参数：
  #   $1 - 校验函数名
  #   $2 - 失败时的提示信息（仅供上层使用）
  #
  # 返回：
  #   0 - 校验通过
  #   1 - 校验失败

  local check_func="$1"
  # 保存函数名

  # shellcheck disable=SC2086
  $check_func
  # 执行传入的校验函数

  return $?
  # 原样返回校验结果
}
