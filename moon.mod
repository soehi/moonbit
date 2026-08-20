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

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/soehi/moonbit"

license = "Apache-2.0"

keywords = [ "cli", "shell", "ls", "grep", "find", "cat", "terminal", "tools" ]

preferred_target = "native"

description = "现代化 Shell 命令行工具集 — ls/cat/find/grep/wc/head/tail/stat"

import {
  "moonbitlang/async@0.21.0",
}
