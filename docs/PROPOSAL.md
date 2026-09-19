# 2026 MoonBit 国产基础软件开源大赛-9月黑客松 项目申报

## 1. 项目名称

tiny-httpd-moonbit —— 经典极简 HTTP 服务器 tinyhttpd 的 MoonBit 复刻版

## 2. 项目简介

tinyhttpd 是 1999 年用 C 写成的约 500 行 HTTP 服务器，二十多年来被当作理解
Web 服务器原理的第一份教材。本项目用纯 MoonBit 将它整体复刻：HTTP/1.0 报文
解析、静态文件服务、CGI 动态执行、错误页这些骨架原样保留，工程上则按现代标准
重做——请求与响应是纯函数的强类型模型，动态端点由 trait 在进程内执行而不再
fork 子进程，页面内嵌进二进制（VFS）从而单文件可跑、路径穿越天然不可能。
全项目约 600 行 MoonBit 源码、35 个自动化测试，native 构建出的单个可执行文件
已在 Windows 真机上通过 curl 对全部端点的实测，wasm-gc 与 js 后端编译并通过
同一套测试。

## 3. 项目方向与通用性说明

方向：国产编程语言生态的基础软件。Web 服务器是通用性最强的基础软件形态之一，
tinyhttpd 又是其中公认的教学母本——用一门新语言复刻它，等于把语言在类型系统、
FFI、跨后端编译、包管理、测试工具链上的真实水位当众量一遍，也给后来的 MoonBit
学习者留一份可以直接读懂、可以直接跑的服务器参考实现。`http` 包（报文解析与
序列化）和 `server` 包（`Connection`/`CgiProgram` trait）是独立可复用的库，
不与命令行入口绑定。

## 4. 预期使用场景

1. **教学与源码阅读**。MoonBit 初学者按 README 的架构图从 `http` 包读到
   `cmd`，配合 35 个测试理解"字节流如何变成 HTTP 响应"；也可作为高校
   计算机网络课的实验底座，让学生在 `CgiProgram` 上加自己的动态端点。
2. **单二进制的内网小服务**。页面内嵌 VFS、无需任何运行时依赖，`moon build
   --target native --release` 产出一个可执行文件即可在设备或内网机上起一个
   带动态端点的管理页/状态页（演示站点 `/`、`/cgi-bin/env.cgi`、
   `/cgi-bin/color.cgi` 即为此设计）。
3. **WASM 沙箱环境的服务器逻辑验证**。wasm-gc/js 后端没有 socket，但请求
   管线完全一致：把 HTTP 解析、路由、CGI 逻辑带进浏览器扩展、边缘函数等
   无法开端口的场景里，用内存连接测试完整的字节级行为。
4. **MoonBit Web 框架的种子组件**。`Request`/`Response` 模型与 trait 化的
   连接抽象可以直接被更大规模的框架项目吸收，作为最内核的那一层。

## 5. 拟实现的核心功能

- HTTP/1.0 请求解析：请求行、头、Content-Length 请求体、查询串 percent 解码（已完成）
- 响应模型与字节级序列化，头按字典序确定性输出；HEAD/404/501/400 语义（已完成）
- 内嵌 VFS 静态服务：路径规范化、MIME 推断、防目录穿越（已完成）
- 进程内 CGI：CGI 1.1 meta-variables 构造、SSI 风格模板引擎（env.cgi）、
  可编程动态端点 `CgiProgram`（color.cgi），参数消毒防注入（已完成）
- 跨后端 TCP 前端：`Connection` trait + 约 100 行 C shim（Windows 动态解析
  winsock，无需额外链接参数），wasm/js 内存桩（已完成）
- 计划中：连接级并发、`/server-info` 内省端点、mooncake 包发布

## 6. 项目性质

移植项目（在原版设计基础上的完整重写，未复制原 C 代码）。

## 7. 参考项目说明

- 参考项目：tinyhttpd（J. David Blackstone，1999）
- 来源链接：https://sourceforge.net/projects/tinyhttpd/
- 许可证：GNU General Public License。本项目据此以 GPL-2.0-or-later 发布，
  仓库 NOTICE 文件中保留了完整的出处与署名说明。

## 8. GitHub 仓库链接

https://github.com/soehi/tinyhttpd-moonbit
（主分支 main，16 个有效提交：按功能拆分的 http/server/CI/文档系列提交，
另含测试与真机验证修复记录。）
