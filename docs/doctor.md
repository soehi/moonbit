# moonsh doctor 使用文档

`doctor` 是 moonsh 面向 MoonBit 工作区的工程健康检查器。它只读取目录结构，不执行项目中的脚本或外部命令。

## 快速开始

```bash
moon run cmd/main -- doctor .
```

典型输出：

```text
MoonBit workspace health: A (100/100)
sources=22 tests=3 packages=2 untested_packages=0
[PASS] module: 找到根目录 moon.mod
[PASS] readme: 找到项目 README
[PASS] license: 找到开源许可证
[PASS] ci: 找到 GitHub Actions 工作流
[PASS] packages: 找到 2 个 MoonBit 包
[PASS] sources: 找到 22 个 MoonBit 源文件
[PASS] tests: 找到 3 个测试文件
[PASS] package-tests: 每个包目录都包含测试文件
```

## 输出格式

### 终端文本

```bash
moon run cmd/main -- doctor --format text .
```

默认格式，显示 A–F 等级、总分、统计数据和逐项诊断。

### JSON

```bash
moon run cmd/main -- doctor --format json .
```

适合 CI、编辑器或其他程序读取。主要字段包括：

- `score`、`grade`：数值分数和 A–F 等级；
- `moonbitFiles`、`testFiles`、`packages`：工程统计；
- `untestedPackages`：同目录没有测试文件的包数量；
- `findings`：包含严重级别、规则代码和说明的诊断数组。

### GitHub Markdown

```bash
moon run cmd/main -- doctor --format markdown .
```

可将输出写入 GitHub Actions 的 `$GITHUB_STEP_SUMMARY`，形成诊断表格。

### README 徽章

```bash
moon run cmd/main -- doctor --format badge .
```

输出可直接粘贴到 README 的 shields.io Markdown；颜色会随健康等级变化。

## 当前规则

| 规则代码 | 检查内容 | 分值 |
|---|---|---:|
| `module` | 根目录包含 `moon.mod` | 20 |
| `readme` | 根目录包含 README | 15 |
| `license` | 根目录包含 LICENSE | 10 |
| `ci` | 包含 GitHub Actions 工作流 | 10 |
| `packages` | 至少包含一个 `moon.pkg` | 10 |
| `sources` | 至少包含一个 `.mbt` 文件 | 20 |
| `tests` | 至少包含一个 MoonBit 测试文件 | 15 |
| `package-tests` | 每个包目录是否有同目录测试 | 提示项 |

扫描会忽略 `.git`、`.mooncakes`、`_build`、`target` 和 `node_modules`，最大递归深度为 32。

## 库 API

`audit_workspace` 是无文件系统副作用的纯函数，可以被其他 MoonBit 包复用：

```moonbit
let report = @moonsh.audit_workspace([
  "moon.mod",
  "moon.pkg",
  "README.md",
  "LICENSE",
  ".github/workflows/ci.yml",
  "main.mbt",
  "main_test.mbt",
])
inspect(report.score, content="100")
```

可使用以下格式化函数生成不同输出：

- `format_workspace_audit`
- `format_workspace_audit_json`
- `format_workspace_audit_markdown`
- `format_workspace_audit_badge`

## 验证

```bash
moon check
moon test
moon run cmd/main -- doctor .
```
