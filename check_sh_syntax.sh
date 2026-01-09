#!/usr/bin/env bash
# ==============================================
# 批量检查 Shell 脚本语法和空函数
# 用法: ./check_sh_syntax.sh /path/to/scripts
# ==============================================

TARGET_DIR="${1:-.}"  # 默认当前目录

echo "🔍 检查目录: $TARGET_DIR 下的所有 .sh 文件"

# 查找所有 .sh 文件
sh_files=$(find "$TARGET_DIR" -type f -name "*.sh")

# 初始化标记
syntax_errors=0
empty_functions=0

for file in $sh_files; do
    echo "-------------------------------"
    echo "检查文件: $file"

    # 1. 语法检查
    if ! bash -n "$file" 2>/tmp/bash_syntax_err.log; then
        echo "✘ 语法错误:"
        cat /tmp/bash_syntax_err.log
        syntax_errors=$((syntax_errors+1))
    else
        echo "✔ 语法通过"
    fi

    # 2. 空函数检查
    # 匹配: function foo() {} 或 foo() {}
    empty_funcs=$(grep -E '^[[:space:]]*(function[[:space:]]+)?[a-zA-Z0-9_]+[[:space:]]*\(\)[[:space:]]*\{\s*\}' "$file")
    if [ -n "$empty_funcs" ]; then
        echo "⚠ 空函数声明:"
        echo "$empty_funcs"
        empty_functions=$((empty_functions+1))
    fi
done

echo "==============================="
echo "检查完成: "
echo "语法错误文件数量: $syntax_errors"
echo "空函数数量: $empty_functions"
