#!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - lib/utils.sh
#
# @文件路径: [相对路径]
# @功能描述: 负责 “算” (字符串处理、路径计算、数学运算)
# @项目地址: [如果是第三方]
#
# @职责:
# 1. 提供模块通用功能函数
# 2. 支持系统判断、输入验证、等待、路径处理等
# 3. 不包含业务逻辑
#
# @作者: Jamison
# @版本: 0.1.0
# @创建日期: 2025-12-31
# ==============================================================================

# ------------------------------
# 输入校验
# ------------------------------

# TODO 后续删掉
is_number() {
  # 参数 $1：输入值
  # 返回 0 表示是纯数字，1 表示不是
  [[ "$1" =~ ^[0-9]+$ ]]
}

# ------------------------------------------------------------------------------
# 函数名: current_time
# 功能:   获取当前日期时间函数
# 
# 参数: 无
# 
# 返回值: 无
# 
# 示例:
#   current_time
# ------------------------------------------------------------------------------
current_time() {
  # 当前时间，格式: YYYY-MM-DD HH:MM:SS
  date "+%Y-%m-%d %H:%M:%S"
}

# ------------------------------------------------------------------------------
# 函数名: command_exists
# 功能:   命令存在性检查
# 
# 参数:
#   $1 (string): 命令名称 (必填)
# 
# 返回值:
#   0 - 存在该命令
#   1 - 不存在该命令
# 
# 示例:
#   command_exists
# ------------------------------------------------------------------------------
command_exists() {
  # 参数 $1：命令名
  local cmd="$1"

  # 使用 type 命令判断是否存在
  if type "$cmd" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# 函数名: get_docker_status_text
# 功能:   辅助函数: 获取 Docker 环境状态字符串
# 
# 参数:w
#   无
# 
# 返回值:
#   0 - 已安装
#   1 - 未安装
# 
# 示例:
#   get_docker_status_text
# ------------------------------------------------------------------------------
get_docker_status_text() {
  if check_docker; then
    print_echo "${BOLD_GREEN}已安装${NC}"
  else
    print_echo "${BOLD_RED}未安装${NC}"
  fi
}

# 修复 dpkg 中断状态（防止清理失败）
fix_dpkg() {
    # 1. 礼貌停止：尝试让 apt/dpkg 正常保存数据并退出
    # (killall 默认发送 SIGTERM 信号，给进程机会收尾)
    killall apt apt-get dpkg 2>/dev/null
    print_step "等待后台任务释放..."
    sleep 3

    # 2. 强制清场：如果礼貌停止后进程还在（卡死了），再强制杀掉
    # (这一步是防止上面的 killall 没杀掉，导致后面删锁时发生冲突)
    pkill -9 -f 'apt|dpkg' 2>/dev/null

    # 3. 清理锁文件：这时候由于进程肯定没了，如果是异常退出的，锁文件可能还在，手动删掉
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock

    # 4. 修复环境：处理刚才可能中断的安装包
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a

    # 5. 执行更新：此时环境已经干净且修复完毕
}

# 刷新 hash
refresh_hash() {
  hash -r 2>/dev/null
}

# ------------------------------------------------------------------------------
# 函数名: run_step
# 功能:   执行命令并显示加载动画，完成后在同一行显示结果
# 
# 参数:
#   -m | --message      (字符串): [必填] 提示信息 (例如: "正在备份")
#   -s | --success-msg  (字符串): [可选] 成功时的后缀 (默认: "完成")
#   -e | --error-msg    (字符串): [可选] 失败时的后缀 (默认: "失败")
#   -- <命令>           (其余):   [必填] 要执行的具体命令
# 
# 示例:
#   run_step -m "备份配置" -- cp /a /b
#   run_step -m "测试连通性" -s "正常" -e "不通" -- ping -c 1 8.8.8.8
# ------------------------------------------------------------------------------
run_step() {
    local message=""
    local success_msg="完成"  # 默认成功文案
    local error_msg="失败"    # 默认失败文案
    local cmd=()
    local sleep=1            # 默认时间 1 秒

    # 1. 解析参数
    # 使用 while 循环解析，遇到 -- 则停止解析，后面的全部作为命令
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message)
                message="$2"
                shift 2
                ;;
            -s|--success-msg)
                success_msg="$2"
                shift 2
                ;;
            -e|--error-msg)
                error_msg="$2"
                shift 2
                ;;
            -S|--sleep)
                sleep="$2"
                shift 2
                ;;
            --) # 遇到 -- 停止解析，后面全是命令
                shift 1
                cmd=("$@")
                break
                ;;
            *)
                # 兼容旧写法: run_step "消息" cmd...
                # 如果第一个参数不是 flag 且 cmd 为空，视为 message
                if [[ -z "$message" ]]; then
                    message="$1"
                    shift 1
                    # 如果没有用 -- 分隔，剩下的所有参数视为命令
                    if [[ $# -gt 0 ]]; then
                        cmd=("$@")
                        break
                    fi
                else
                    # 已经有 message 了，视为命令的一部分 (这种情况比较少见，建议用 --)
                    cmd=("$@")
                    break
                fi
                ;;
        esac
    done

    # 2. 定义转圈动画
    local spin='-\|/'
    local i=0
    local delay=0.1

    (
        tput civis
        while true; do
            i=$(( (i+1) % 4 ))
            # \r 回到行首
            print_echo -ne "\r${BLUE}[${spin:$i:1}]${NC} ${message}..."
            sleep "$delay"
        done
    ) &

    # 稍微等一下让转圈先出来，避免闪烁
    # (如果命令极快，可以去掉这个 sleep 或者设小一点)
    # sleep 0.1 
    
    local spinner_pid=$!

    # 3. 执行真正的命令
    "${cmd[@]}" >/dev/null 2>&1
    local exit_code=$?

    sleep "$sleep"

    # 4. 杀掉转圈进程
    kill "$spinner_pid" >/dev/null 2>&1
    wait "$spinner_pid" 2>/dev/null

    # 5. 根据返回值显示最终结果
    if [ $exit_code -eq 0 ]; then
        print_echo -ne "\r${GREEN}[✔]${NC} ${message}... ${GREEN}${success_msg}${NC}     \n"
        tput cnorm
        return 0
    else
        print_echo -ne "\r${RED}[✘]${NC} ${message}... ${RED}${error_msg}${NC}     \n"
        tput cnorm
        return 1
    fi
}
