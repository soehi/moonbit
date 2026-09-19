# tiny-httpd-moonbit

用纯 MoonBit 复刻的经典极简 HTTP 服务器 —— J. David Blackstone 在 1999 年写的
tinyhttpd（约 500 行 C）是无数人理解 Web 服务器原理的第一课。本项目用 MoonBit
把它带到 2026 年：保留原版的极简与可读，补上现代工程该有的部分。

```
tiny-httpd-moonbit 0.1.0 - MoonBit port of tinyhttpd (GPL)
listening on http://127.0.0.1:8080/ (Ctrl+C to stop)
```

## 特性

- **纯 MoonBit 实现**（约 600 行源码 + 900 行测试）：请求解析、路由、CGI、
  响应构造全部用 MoonBit 表达，只有 100 行左右的 C 用于 socket 绑定
- **单文件自包含**：页面内嵌在二进制里（VFS），没有 `htdocs` 目录也能跑，
  路径穿越（`../`）从构造上就不可能
- **进程内 CGI**：保留原版 CGI 语义（meta-variables 进、HTTP 响应出），
  但程序在服务器进程内执行 —— 原版是 fork 一个 shell 子进程
- **SSI 风格动态页**：`env.cgi` 是一个模板文件，由服务器解析
  `<!--#echo var="QUERY_STRING" -->` 指令
- **跨后端**：native（真实 TCP 服务器）/ wasm-gc / js 全部可编译可测试，
  非原生后端用内存连接跑同一套请求管线
- **认真的测试**：35 个测试覆盖 percent 解码、报文解析、SSI 渲染、
  缓冲区跨块重组、端到端字节级管线

## 快速开始

```bash
# 安装 MoonBit: https://docs.moonbitlang.com (或 curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash)

moon build --target native --release   # 生成原生可执行文件
./_build/native/release/build/cmd/main/main.exe --port 8080
```

然后在浏览器或 curl 里试：

| 地址 | 效果 |
| --- | --- |
| `/` | 内嵌的 index 页面 |
| `/cgi-bin/env.cgi?name=Jim` | SSI 渲染的 CGI 环境变量表 |
| `/cgi-bin/color.cgi?color=%2300ff00` | 动态生成的彩色页面（参数已消毒） |
| `/nope` | 404 错误页 |
| `DELETE /` | 501 Not Implemented（和原版一致） |

其他命令：

```bash
moon run cmd/main            # 直接以 wasm-gc 运行（无 socket，会提示绑定失败）
moon test                    # 35 个测试
moon check                   # 类型检查（零警告）
```

## 架构

```
cmd/main        CLI：参数解析、banner、accept 循环
server
 ├ tcp/FFI      Connection trait + native C shim（100 行）+ wasm/js 内存桩
 ├ conn         缓冲读取器：字节流 → HTTP 请求（含 Content-Length body）
 ├ vfs          内嵌文档根：规范化路径、防穿越
 ├ cgi          CGI 1.1 meta-variables、SSI 渲染器、color.cgi
 └ handler      App 路由：静态 / CGI / 错误页，请求日志
http            纯函数 HTTP 模型：percent/query 解码、请求解析、
                响应序列化（字典序确定性输出）、MIME、HTML 转义
```

## 相对原版 tinyhttpd 的改动

| 原版（1999, C） | 本项目（2026, MoonBit） |
| --- | --- |
| 每请求 fork 子进程执行 CGI | 进程内执行，trait `CgiProgram` 可注册任意 MoonBit 函数 |
| `fopen`/`fgets` 直接读磁盘 | 内嵌 VFS，单二进制自包含，无穿越风险 |
| 管道回写 socket，头靠拼字符串 | `Response` 结构 + 字节级 wire 序列化 |
| CGI 输出原样回传（可注入） | `color.cgi` 参数消毒、错误页 HTML 转义 |
| 单一 Unix 平台 | native / wasm-gc / js 三后端，同一套测试 |
| 无自动化测试 | 35 个测试 + 端到端字节级管线测试 |

原版有的基本都有：HTTP/1.0、GET/POST/HEAD、查询串解码、CGI、
错误页、每次处理一个连接的极简 accept 循环。

## 许可证

GPL-2.0-or-later。原作 tinyhttpd © 1999 J. David Blackstone，采用 GNU GPL
发布；详见 [NOTICE](NOTICE) 与 [LICENSE](LICENSE)。
