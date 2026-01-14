# VpsScriptKit 2026 工业级几何 UI 系统清单

## 1. 核心交互图标 (UI Interaction)

| 功能类型 | 图标 | 字符代码 | 颜色建议 | 视觉语义 |
|----------|------|----------|----------|----------|
| 信息提示 | ● | \u25cf | BOLD_BLUE | 中性状态 / 进程开始 |
| 成功提示 | ✔ | \u2714 | BOLD_GREEN | 任务完成 / 正常 |
| 输入引导 | ➜ | \u279c | LIGHT_CYAN | 动作指向 / 等待输入 |
| 小贴士 | ✦ | \u2726 | BOLD_YELLOW | 额外建议 / 亮点功能 |
| 结束退出 | ■ | \u25a0 | BOLD_GREEN | 运行终止 / 完结感谢 |

## 2. 页面标题图标 (Page Headers)

| 页面模块 | 图标 | 字符代码 | 颜色建议 | 视觉语义 |
|----------|------|----------|----------|----------|
| 首页 Header | ▣ | \u25a3 | BOLD_WHITE | 工具箱 / 综合套件 |
| 系统更新 | ↻ | \u21bb | BOLD_GREEN | 循环 / 持续迭代 |
| 系统工具 | ⚙ | \u2699 | BOLD_WHITE | 机械 / 核心配置 |
| 基础工具 | ⚒ | \u26cf | BOLD_WHITE | 交叉工具 / 维护安装 |
| Docker 管理 | ☵ | \u2635 | BOLD_BLUE | 镜像层 / 容器堆叠 |
| 内存/Swap | ▤ | \u25a4 | BOLD_MAGENTA | 内存插槽 / 存储单元 |
| 节点搭建 | ⑆ | \u2446 | BOLD_CYAN | 网络拓扑 / 链路分发 |
| 测试脚本 | ⧗ | \u29d7 | BOLD_YELLOW | 沙漏 / 实验验证处理 |

## 3. 代码实现规范 (Bash 示例)

```bash
# 标准间距建议使用 $(ui_spaces 1)
ui_info()    { ui echo "${BOLD_BLUE}●$(ui_spaces 1)$1${LIGHT_WHITE}"; }
ui_success() { ui echo "${BOLD_GREEN}✔$(ui_spaces 1)$1${LIGHT_WHITE}"; }
ui_tip()     { ui echo "${BOLD_YELLOW}✦$(ui_spaces 1)$1${LIGHT_WHITE}"; }
ui_exit()    { ui echo "${BOLD_GREEN}■$(ui_spaces 1)$1${LIGHT_WHITE}"; }

# 带参数解析的输入函数 (默认 3 空格美感)
# ui_input --prompt "请输入" --space 3 --default "Y"

# 页面 Header 调用示例
ui print page_header_full "${BOLD_BLUE}☵$(ui_spaces 1)Docker 管理"
ui print page_header_full "${BOLD_GREEN}↻$(ui_spaces 1)VpsScriptKit 系统更新中心"
ui print page_header_full "${BOLD_CYAN}⑆$(ui_spaces 1)节点搭建脚本合集"

```

## 4. 设计优势说明

- 极致对齐：几何字符在所有终端字体中占位固定，解决 Emoji 导致的排版崩坏。
- 专业观感：纯几何设计符合 2026 年 Linux 生产力工具的工业审美。
