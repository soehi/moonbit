// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "shiwork/moonsh"

version = "0.2.0"

readme = "README.mbt.md"

repository = "https://github.com/soehi/moonbit"

license = "Apache-2.0"

keywords = [ "cli", "shell", "ls", "grep", "find", "cat", "terminal", "tools" ]

preferred_target = "native"

description = "MoonBit 工作区健康诊断与跨平台文本处理工具"

import {
  "moonbitlang/async@0.21.0",
}
