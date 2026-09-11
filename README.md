---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: '8ec15c21-a4d9-4192-817d-1b6e96063a77'
  PropagateID: '8ec15c21-a4d9-4192-817d-1b6e96063a77'
  ReservedCode1: 'd5642964-c7a1-4e27-bfea-74b52c0d3172'
  ReservedCode2: 'd5642964-c7a1-4e27-bfea-74b52c0d3172'
---

# moonsh

> 现代化 Shell 命令行工具集 — 用 MoonBit 语言编写的 14 个核心 Unix 命令的现代化重新实现

[![CI](https://github.com/shiwork/moonsh/actions/workflows/ci.yml/badge.svg)](https://github.com/shiwork/moonsh/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![MoonBit](https://img.shields.io/badge/MoonBit-native-orange.svg)](https://moonbitlang.com)

## 简介

`moonsh` 是一个用 [MoonBit](https://moonbitlang.com) 语言编写的命令行工具集，包含了 14 个日常开发中最常用的 Shell 命令。项目灵感来自 Rust 生态中的 [bat](https://github.com/sharkdp/bat)、[eza](https://github.com/eza-community/eza)、[fd](https://github.com/sharkdp/fd) 和 [ripgrep](https://github.com/BurntSushi/ripgrep) 等现代化工具，旨在用纯 MoonBit 重新实现这些经典命令，展示 MoonBit 在系统编程领域的潜力。

### 为什么用 MoonBit？

- **原生性能**：MoonBit 编译到 native 目标，直接生成机器码，无 VM 开销
- **安全内存**：自动内存管理，无 GC 暂停，适合 CLI 工具的快速启动
- **现代语法**：模式匹配、代数数据类型、trait 系统，代码简洁且类型安全
- **自研生态**：不依赖外部 C 库，正则引擎和 glob 匹配均用纯 MoonBit 实现

## 功能一览

| 命令 | 功能说明 | 对标工具 |
|------|---------|---------|
| `ls` | 列出目录内容（短格式/长格式/树形/颜色） | exa / eza |
| `cat` | 查看文件内容（行号/语法高亮/stdin） | bat |
| `find` | 搜索文件（glob 模式/类型过滤/深度控制） | fd |
| `grep` | 文本搜索（正则/行号/反向/上下文/忽略大小写/stdin） | ripgrep |
| `wc` | 统计行数/单词/字符/最大行长度 | wc |
| `head` | 显示文件开头（行数控制/stdin） | head |
| `tail` | 显示文件末尾（行数控制/stdin） | tail |
| `stat` | 显示文件信息（类型/大小/时间戳/权限） | stat |
| `sort` | 排序文本行（字典序/数值/自然/版本/逆序/去重/按字段） | sort |
| `uniq` | 去除相邻重复行（计数/忽略大小写/跳过字段/字符） | uniq |
| `cut` | 提取字段或字符（分隔符/字符位置/字节位置） | cut |
| `tr` | 字符转换/删除/压缩（POSIX 字符类/转义字符） | tr |
| `diff` | 比较文件差异（LCS 算法/统一格式/彩色输出） | diff |
| `md` | Markdown 渲染为 HTML（支持标题/段落/列表/代码块/表格/链接/图片/粗体/斜体/删除线） | pandoc / marked |

## 安装

### 从源码构建

```bash
# 安装 MoonBit 工具链
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

# 克隆仓库
git clone https://github.com/shiwork/moonsh.git
cd moonsh

# 构建项目
moon build --target native

# 运行测试
moon test
```

构建产物位于 `target/native/release/build/cmd/main/main.exe`（Windows）或 `target/native/release/build/cmd/main/main`（Linux/macOS）。

### 通过 mooncakes 安装（库）

```bash
moon add shiwork/moonsh
```

## 使用方法

### ls — 列出目录

```bash
moon run cmd/main -- ls              # 列出当前目录
moon run cmd/main -- ls -a           # 显示隐藏文件
moon run cmd/main -- ls -l           # 长格式（权限+大小+日期）
moon run cmd/main -- ls -t           # 树形显示
moon run cmd/main -- ls -l -c /tmp   # 长格式+颜色
```

### cat — 查看文件

```bash
moon run cmd/main -- cat file.txt          # 查看文件
moon run cmd/main -- cat -n file.txt      # 显示行号
echo "hello" | moon run cmd/main -- cat -  # 从 stdin 读取
```

### find — 搜索文件

```bash
moon run cmd/main -- find .                  # 列出所有文件
moon run cmd/main -- find -n "*.rs" .        # glob 模式匹配
moon run cmd/main -- find --type f .         # 只查找文件
moon run cmd/main -- find --type d .         # 只查找目录
moon run cmd/main -- find -H .               # 包含隐藏文件
moon run cmd/main -- find -d 2 .             # 限制深度
```

### grep — 文本搜索

```bash
moon run cmd/main -- grep "TODO" file.rs          # 搜索文本
moon run cmd/main -- grep -i "error" log.txt      # 忽略大小写
moon run cmd/main -- grep -n -v "test" file.rs     # 行号+反向匹配
moon run cmd/main -- grep -C 2 "pattern" file     # 显示上下文2行
echo "hello" | moon run cmd/main -- grep "ll" -   # 从 stdin 搜索
```

### wc — 统计

```bash
moon run cmd/main -- wc file.txt           # 行/单词/字符/最大行长度
moon run cmd/main -- wc -l file.txt        # 只显示行数
moon run cmd/main -- wc -w file.txt        # 只显示单词数
```

### head / tail — 查看开头/末尾

```bash
moon run cmd/main -- head -n 20 file.txt   # 前20行
moon run cmd/main -- tail -n 5 file.txt    # 后5行
echo "test" | moon run cmd/main -- head -   # 从 stdin 读取
```

### stat — 文件信息

```bash
moon run cmd/main -- stat file.txt    # 显示类型/大小/时间戳/权限
```

### sort — 排序

```bash
moon run cmd/main -- sort file.txt              # 字典序排序
moon run cmd/main -- sort -n numbers.txt        # 数值排序
moon run cmd/main -- sort -r file.txt           # 逆序
moon run cmd/main -- sort -u file.txt           # 排序+去重
moon run cmd/main -- sort --natural file.txt   # 自然排序（file2 < file10）
moon run cmd/main -- sort --version file.txt   # 版本号排序（1.2.3 < 1.10.0）
```

### uniq — 去重

```bash
moon run cmd/main -- uniq file.txt          # 去除相邻重复行
moon run cmd/main -- uniq -c file.txt       # 显示重复次数
moon run cmd/main -- uniq -d file.txt       # 只显示重复行
moon run cmd/main -- uniq -i file.txt       # 忽略大小写
```

### cut — 提取字段

```bash
moon run cmd/main -- cut -d, -f 2 data.csv      # 按逗号分隔，提取第2字段
moon run cmd/main -- cut -c 1-10 file.txt        # 提取第1-10字符
moon run cmd/main -- cut -b 1-5 file.txt        # 提取第1-5字节
```

### tr — 字符转换

```bash
echo "Hello" | moon run cmd/main -- tr 'a-z' 'A-Z'    # 转大写
echo "hello" | moon run cmd/main -- tr -d 'aeiou'      # 删除元音
echo "aaabbb" | moon run cmd/main -- tr -s 'a'          # 压缩重复
echo "abc" | moon run cmd/main -- tr -c 'a-z' '\n'     # 反转字符集
```

### diff — 文件比较

```bash
moon run cmd/main -- diff old.txt new.txt           # 比较差异
moon run cmd/main -- diff -c old.txt new.txt        # 彩色输出
```

### md — Markdown 渲染

```bash
moon run cmd/main -- md file.md                     # Markdown 转 HTML
moon run cmd/main -- md -f file.md                  # 生成完整 HTML 文档
moon run cmd/main -- md -t "My Doc" file.md         # 指定文档标题
echo "# Hello" | moon run cmd/main -- md -          # 从 stdin 读取
```

## 项目结构

```
moonsh/
├── moon.mod              # 模块配置
├── moon.pkg              # 库包配置
├── moonsh.mbt            # 公共工具（颜色/格式化/文件类型/权限/时间戳）
├── glob.mbt              # Glob 匹配引擎（* ? [abc] [a-z] ** 跨目录）
├── regex.mbt             # 简化正则引擎（. * + ? ^ $ [] \d \w \s \b ()）
├── path.mbt              # 路径处理工具
├── ls.mbt                # ls 命令
├── cat.mbt               # cat 命令
├── find.mbt              # find 命令
├── grep.mbt              # grep 命令
├── wc.mbt                # wc 命令
├── head_tail.mbt         # head / tail 命令
├── stat.mbt              # stat 命令
├── sort.mbt              # sort 命令
├── uniq.mbt              # uniq 命令
├── cut.mbt               # cut 命令
├── tr.mbt                # tr 命令
├── diff.mbt              # diff 命令
├── markdown.mbt          # Markdown 解析器和 HTML 渲染器
├── moonsh_test.mbt       # 黑盒测试
├── moonsh_wbtest.mbt     # 白盒测试
├── cmd/main/
│   ├── main.mbt         # CLI 入口（argparse 子命令分发）
│   └── moon.pkg         # 可执行包配置
├── .github/workflows/
│   └── ci.yml           # GitHub Actions CI
├── AGENTS.md            # 项目编码规范
├── LICENSE              # Apache-2.0
└── README.md
```

## 技术特点

### 自研引擎

- **Glob 匹配引擎**：支持 `*`、`?`、`[abc]`、`[a-z]`、`[!abc]` 和 `**` 跨目录匹配，用于 `find` 命令的文件名过滤
- **正则表达式引擎**：支持 `.`、`*`、`+`、`?`、`^`、`$`、`[a-z]`、`[^abc]`、`\d`、`\w`、`\s`、`\b`、`()` 分组，采用贪心匹配 + 回溯策略，用于 `grep` 命令的文本搜索
- **LCS 差异算法**：基于最长公共子序列的文本差异比较，用于 `diff` 命令
- **Markdown 解析器**：纯 MoonBit 实现的 Markdown 解析器，支持标题、段落、列表、代码块、引用、链接、图片、粗体、斜体、删除线、表格等语法

### 异步 I/O

所有文件操作基于 `moonbitlang/async` 的异步 fs 包，使用 native 后端直接调用系统 API，实现高性能的非阻塞 I/O。

### 测试覆盖

项目包含 **175 个测试用例**，覆盖所有命令的核心功能和边界条件：

- 黑盒测试（`moonsh_test.mbt`）：测试公开 API 的输入输出
- 白盒测试（`moonsh_wbtest.mbt`）：测试内部实现细节

```bash
# 运行全部测试
moon test

# 查看覆盖率
moon coverage analyze
```

## 开发指南

### 环境要求

- MoonBit 工具链 v0.1.20260819 或更高版本
- Native 后端（项目 `preferred_target = native`）

### 开发流程

```bash
# 安装依赖
moon install

# 格式化代码
moon fmt

# 类型检查
moon check

# 构建
moon build --target native

# 运行测试
moon test

# 更新接口文件
moon info

# 查看代码覆盖率
moon coverage analyze
```

### 编码规范

- MoonBit 代码使用 block style，各 block 以 `///|` 分隔
- 使用 `moon fmt` 格式化代码
- 使用 `moon info` 更新生成的接口文件（`.mbti`）
- 使用 `assert_eq` 或 `assert_true(pattern is Pattern(...))` 进行断言测试
- 开发完成后运行 `moon info && moon fmt` 更新接口并格式化

## 技术栈

| 组件 | 说明 |
|------|------|
| 语言 | [MoonBit](https://moonbitlang.com) v0.1.20260819 |
| 后端 | Native（直接编译到机器码） |
| 异步 I/O | `moonbitlang/async@0.21.0`（fs / stdio / io） |
| 参数解析 | `moonbitlang/core/argparse` |
| 字符串处理 | `moonbitlang/core/string` |
| 许可证 | Apache-2.0 |

## 许可证

本项目采用 [Apache License 2.0](LICENSE) 开源许可证。

> AI生成