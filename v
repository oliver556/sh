# #!/usr/bin/env bash

# ==============================================================================
# VpsScriptKit - 启动包装器
# 
# @文件路径: v
# @功能描述: 解析软链接真实路径，并导出 BASE_DIR 环境供全局使用
# 
# @作者:    Jamison
# @版本:    1.0.0
# @创建日期: 2026-01-09
# ==============================================================================

# 获取当前脚本的真实物理路径
REAL_PATH=$(readlink -f "$0")

# 获取当前脚本的绝对真实路径路径
export BASE_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"

# 执行主入口，并传递所有参数 ($@)
# 使用 exec 可以让 main.sh 接管当前进程，更加高效
if [ -f "$BASE_DIR/main.sh" ]; then
    exec "$BASE_DIR/main.sh" "$@"
else
    echo "错误: 未找到主程序入口 $BASE_DIR/main.sh"
    exit 1
fi
