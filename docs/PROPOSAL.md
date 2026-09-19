# tinyhttpd-moonbit 项目申报书

## 基本信息

- 参赛者：soehi
- 联系方式：811446351@qq.com
- 仓库：https://github.com/soehi/tinyhttpd-moonbit
- 方向：基础软件 / 网络服务
- 许可证：GPL-2.0-or-later
- 类型：移植项目

## 项目目标

tinyhttpd-moonbit 是一个用 MoonBit 重写的极简 HTTP 服务器。原型是 J. David Blackstone 在 1999 年写的 tinyhttpd，约 500 行 C，常被用来学习 Web 服务器的原理。本项目保留原版的骨架：HTTP/1.0 请求解析、静态文件、CGI、错误页，全部改用 MoonBit 实现，页面内嵌在二进制里，CGI 在进程内执行，native 编译出单个可执行文件，wasm 也能跑同一套逻辑。

## 真实需求

想理解 HTTP 服务器的人，最缺一份读得懂、跑得起、能动手改的完整实现。原版 tinyhttpd 只能在类 Unix 上编译，CGI 靠 fork 子进程，也没有测试。MoonBit 生态目前缺这样的入门级服务器示例。用新语言复刻经典程序，既能实际检验 MoonBit 在 FFI、测试和跨后端编译上的能力，做完的东西也能留下来给后面学习的人用。

## 使用场景

1. 学习 MoonBit 和 HTTP 协议：配合仓库里的 35 个测试，从 percent 解码读到响应序列化，理解字节流怎么变成 HTTP 响应。
2. 内网小服务：静态页面内嵌、无外部依赖，编译出一个文件拷到内网机器就能起状态页或管理页，带自己的动态端点。
3. 无 socket 环境的逻辑验证：wasm/js 后端用内存连接跑同一套请求处理，可用在浏览器扩展等开不了端口的场景。

## 参考项目

- 项目：tinyhttpd（J. David Blackstone，1999）
- 来源：https://sourceforge.net/projects/tinyhttpd/
- 许可证：GNU GPL。本项目因此以 GPL-2.0-or-later 发布，未复制原 C 代码，出处说明在仓库 NOTICE 文件中。

## 拟实现功能

1. HTTP/1.0 请求行、请求头、查询串和 Content-Length 请求体解析。
2. 静态文件服务：内嵌 VFS、MIME 推断、路径规范化防穿越。
3. CGI：构造 CGI 1.1 环境变量，进程内执行动态端点，SSI 风格模板渲染 env.cgi。
4. 响应序列化：字典序确定性的响应头，HEAD、404、501、400 语义，HTML 转义。
5. 跨后端支持：native 用约 100 行 C 绑定 socket，wasm-gc/js 用内存连接，测试共用。
6. 输入消毒：动态端点参数白名单过滤，错误页转义，避免注入。

## 预期成果与生态价值

交付可运行的 tiny-httpd 命令、http 和 server 两个可复用的 MoonBit 包、35 个自动化测试和使用文档。目前命令已在 Windows 真机上运行并通过 curl 实测。服务器逻辑不依赖文件系统，HTTP 解析和路由骨架可以直接被其他 MoonBit 项目复用，使用者不需要采用 MoonBit 工程。
