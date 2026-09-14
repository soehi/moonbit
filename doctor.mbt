// doctor.mbt — MoonBit 工作区健康检查
// 该命令在通用文件命令之上提供工程级诊断，不执行外部进程。

///|
/// 诊断项的严重级别。
pub enum AuditSeverity {
  Pass
  Warning
  Error
}

///|
/// 一条可操作的工作区诊断。
pub struct AuditFinding {
  severity : AuditSeverity
  code : String
  message : String
}

///|
/// MoonBit 工作区健康报告。
pub struct WorkspaceAudit {
  score : Int
  moonbit_files : Int
  test_files : Int
  packages : Int
  findings : Array[AuditFinding]
}

///|
/// 根据相对文件路径生成确定性的工作区健康报告。
///
/// 该纯函数不访问文件系统，便于编辑器、CI 和其他 MoonBit 程序复用。
pub fn audit_workspace(files : Array[String]) -> WorkspaceAudit {
  let normalized : Array[String] = []
  for file in files {
    normalized.push(normalize_separators(file).to_lower())
  }
  let mut moonbit_files = 0
  let mut test_files = 0
  let mut packages = 0
  let mut has_module = false
  let mut has_readme = false
  let mut has_license = false
  let mut has_ci = false
  for file in normalized {
    if file == "moon.mod" {
      has_module = true
    }
    if file == "readme.md" || file == "readme.mbt.md" {
      has_readme = true
    }
    if file == "license" || file.has_prefix("license.") {
      has_license = true
    }
    if file.has_prefix(".github/workflows/") &&
      (file.has_suffix(".yml") || file.has_suffix(".yaml")) {
      has_ci = true
    }
    if file.has_suffix(".mbt") {
      moonbit_files = moonbit_files + 1
      if file.has_suffix("_test.mbt") || file.has_suffix("_wbtest.mbt") {
        test_files = test_files + 1
      }
    }
    if file == "moon.pkg" || file.has_suffix("/moon.pkg") {
      packages = packages + 1
    }
  }
  let findings : Array[AuditFinding] = []
  let mut score = 0
  score = score +
    audit_required(
      findings, has_module, 20, "module", "找到根目录 moon.mod", "缺少根目录 moon.mod，无法识别为 MoonBit 模块",
    )
  score = score +
    audit_required(
      findings, has_readme, 15, "readme", "找到项目 README", "缺少 README.md 或 README.mbt.md",
    )
  score = score +
    audit_required(
      findings, has_license, 10, "license", "找到开源许可证", "缺少 LICENSE 文件",
    )
  score = score +
    audit_required(
      findings, has_ci, 10, "ci", "找到 GitHub Actions 工作流", "缺少 .github/workflows 下的 CI 配置",
    )
  score = score +
    audit_count(
      findings, packages, 10, "packages", "MoonBit 包", "没有找到 moon.pkg",
    )
  score = score +
    audit_count(
      findings, moonbit_files, 20, "sources", "MoonBit 源文件", "没有找到 .mbt 源文件",
    )
  score = score +
    audit_count(
      findings, test_files, 15, "tests", "测试文件", "没有找到 _test.mbt 或 _wbtest.mbt 测试文件",
    )
  { score, moonbit_files, test_files, packages, findings }
}

///|
fn audit_required(
  findings : Array[AuditFinding],
  present : Bool,
  points : Int,
  code : String,
  pass_message : String,
  error_message : String,
) -> Int {
  if present {
    findings.push({ severity: Pass, code, message: pass_message })
    points
  } else {
    findings.push({ severity: Error, code, message: error_message })
    0
  }
}

///|
fn audit_count(
  findings : Array[AuditFinding],
  count : Int,
  points : Int,
  code : String,
  label : String,
  warning_message : String,
) -> Int {
  if count > 0 {
    findings.push({
      severity: Pass,
      code,
      message: "找到 \{count} 个\{label}",
    })
    points
  } else {
    findings.push({ severity: Warning, code, message: warning_message })
    0
  }
}

///|
/// 格式化健康报告，输出稳定，适合 CI 日志和快照测试。
pub fn format_workspace_audit(audit : WorkspaceAudit) -> String {
  let buf = StringBuilder::new()
  buf.write_string("MoonBit workspace health: \{audit.score}/100\n")
  buf.write_string(
    "sources=\{audit.moonbit_files} tests=\{audit.test_files} packages=\{audit.packages}\n",
  )
  for finding in audit.findings {
    let marker = match finding.severity {
      Pass => "PASS"
      Warning => "WARN"
      Error => "FAIL"
    }
    buf.write_string("[\{marker}] \{finding.code}: \{finding.message}\n")
  }
  buf.to_string()
}

///|
/// 运行 `moonsh doctor` 命令。
pub async fn run_doctor(matches : @argparse.Matches) -> Unit {
  let root = get_positional(matches.values, "path", ".")
  let files : Array[String] = []
  collect_workspace_files(root, "", files, 0)
  let report = audit_workspace(files)
  @stdio.stdout.write(format_workspace_audit(report))
}

///|
async fn collect_workspace_files(
  root : String,
  relative : String,
  files : Array[String],
  depth : Int,
) -> Unit {
  if depth > 32 {
    return
  }
  let current = if relative == "" { root } else { "\{root}/\{relative}" }
  let entries = @fs.readdir(current, include_hidden=true, sort=true) catch {
    _ => return
  }
  for name in entries {
    if name == ".git" ||
      name == ".mooncakes" ||
      name == "_build" ||
      name == "target" ||
      name == "node_modules" {
      continue
    }
    let child_relative = if relative == "" {
      name
    } else {
      "\{relative}/\{name}"
    }
    let full_path = "\{root}/\{child_relative}"
    let is_dir = try (@fs.kind(full_path) is Directory) catch {
      _ => false
    }
    if is_dir {
      collect_workspace_files(root, child_relative, files, depth + 1)
    } else {
      files.push(child_relative)
    }
  }
}
