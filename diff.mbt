// diff.mbt — diff 命令：文本差异比较
// 基于 LCS（最长公共子序列）算法

///|
/// 差异操作类型
pub enum DiffOp {
  /// 上下文行（两文件相同）
  Equal
  /// 只在旧文件中存在
  OnlyOld
  /// 只在新文件中存在
  OnlyNew
  /// 修改行（旧→新）
  Changed
}

///|
/// 差异行
pub struct DiffLine {
  /// 操作类型
  op : DiffOp
  /// 旧行号（1-based, 0 表示不存在）
  old_line_no : Int
  /// 新行号（1-based, 0 表示不存在）
  new_line_no : Int
  /// 行内容
  content : String
  /// 新内容（仅 Changed 时有值）
  new_content : String
}

///|
/// 差异结果
pub struct DiffResult {
  /// 差异行列表
  lines : Array[DiffLine]
  /// 新增行数
  added : Int
  /// 删除行数
  deleted : Int
  /// 修改行数
  changed : Int
}

///|
/// 比较两个文本的差异
pub fn diff_text(old_text : String, new_text : String) -> DiffResult {
  let old_lines = split_lines(old_text)
  let new_lines = split_lines(new_text)
  diff_lines(old_lines, new_lines)
}

///|
/// 比较两行数组的差异
pub fn diff_lines(
  old_lines : Array[String],
  new_lines : Array[String],
) -> DiffResult {
  // 计算 LCS 表
  let lcs = compute_lcs_table(old_lines, new_lines)
  // 回溯生成差异
  let diff_lines : Array[DiffLine] = []
  let mut added = 0
  let mut deleted = 0
  let changed = 0
  let mut i = old_lines.length()
  let mut j = new_lines.length()
  // 从后往前回溯
  while i > 0 || j > 0 {
    if i > 0 && j > 0 && old_lines[i - 1] == new_lines[j - 1] {
      // 相同行
      diff_lines.push({
        op: Equal,
        old_line_no: i,
        new_line_no: j,
        content: old_lines[i - 1],
        new_content: "",
      })
      i = i - 1
      j = j - 1
    } else if j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j]) {
      // 新增行
      diff_lines.push({
        op: OnlyNew,
        old_line_no: 0,
        new_line_no: j,
        content: new_lines[j - 1],
        new_content: "",
      })
      added = added + 1
      j = j - 1
    } else {
      // 删除行
      diff_lines.push({
        op: OnlyOld,
        old_line_no: i,
        new_line_no: 0,
        content: old_lines[i - 1],
        new_content: "",
      })
      deleted = deleted + 1
      i = i - 1
    }
  }
  // 反转（因为我们是从后往前的）
  let reversed : Array[DiffLine] = []
  let mut k = diff_lines.length() - 1
  while k >= 0 {
    reversed.push(diff_lines[k])
    k = k - 1
  }
  { lines: reversed, added, deleted, changed }
}

///|
/// 计算 LCS 表
fn compute_lcs_table(a : Array[String], b : Array[String]) -> Array[Array[Int]] {
  let m = a.length()
  let n = b.length()
  // 初始化 (m+1) x (n+1) 表
  let table : Array[Array[Int]] = []
  let mut i = 0
  while i <= m {
    let row : Array[Int] = []
    let mut j = 0
    while j <= n {
      row.push(0)
      j = j + 1
    }
    table.push(row)
    i = i + 1
  }
  // 填表
  i = 1
  while i <= m {
    let mut j = 1
    while j <= n {
      if a[i - 1] == b[j - 1] {
        table[i][j] = table[i - 1][j - 1] + 1
      } else {
        let up = table[i - 1][j]
        let left = table[i][j - 1]
        table[i][j] = if up >= left { up } else { left }
      }
      j = j + 1
    }
    i = i + 1
  }
  table
}

///|
/// 格式化差异结果为统一 diff 格式
pub fn format_diff(result : DiffResult) -> String {
  let buf = StringBuilder::new()
  for line in result.lines {
    match line.op {
      Equal => {
        buf.write_string("  ")
        buf.write_string(line.content)
        buf.write_char('\n')
      }
      OnlyOld => {
        buf.write_string("- ")
        buf.write_string(line.content)
        buf.write_char('\n')
      }
      OnlyNew => {
        buf.write_string("+ ")
        buf.write_string(line.content)
        buf.write_char('\n')
      }
      Changed => {
        buf.write_string("- ")
        buf.write_string(line.content)
        buf.write_char('\n')
        buf.write_string("+ ")
        buf.write_string(line.new_content)
        buf.write_char('\n')
      }
    }
  }
  let summary = "\n--- \{result.added} additions, \{result.deleted} deletions\n"
  buf.write_string(summary)
  buf.to_string()
}

///|
/// 格式化差异结果为带颜色的输出
pub fn format_diff_colored(result : DiffResult) -> String {
  let buf = StringBuilder::new()
  for line in result.lines {
    match line.op {
      Equal => {
        buf.write_string("  ")
        buf.write_string(line.content)
        buf.write_char('\n')
      }
      OnlyOld => {
        buf.write_string(Color::Red.to_ansi())
        buf.write_string("- ")
        buf.write_string(line.content)
        buf.write_string(Color::Reset.to_ansi())
        buf.write_char('\n')
      }
      OnlyNew => {
        buf.write_string(Color::Green.to_ansi())
        buf.write_string("+ ")
        buf.write_string(line.content)
        buf.write_string(Color::Reset.to_ansi())
        buf.write_char('\n')
      }
      Changed => {
        buf.write_string(Color::Red.to_ansi())
        buf.write_string("- ")
        buf.write_string(line.content)
        buf.write_string(Color::Reset.to_ansi())
        buf.write_char('\n')
        buf.write_string(Color::Green.to_ansi())
        buf.write_string("+ ")
        buf.write_string(line.new_content)
        buf.write_string(Color::Reset.to_ansi())
        buf.write_char('\n')
      }
    }
  }
  buf.to_string()
}

///|
/// 获取差异摘要
pub fn diff_summary(result : DiffResult) -> String {
  "\{result.added} additions(+), \{result.deleted} deletions(-), \{result.changed} changes(~)"
}

///|
/// 判断两文本是否相同
pub fn text_equal(a : String, b : String) -> Bool {
  a == b
}

///|
/// 获取行级别的差异（简化的行号列表）
pub fn line_level_diff(
  old_lines : Array[String],
  new_lines : Array[String],
) -> Array[(DiffOp, Int, Int)] {
  let result = diff_lines(old_lines, new_lines)
  let summary : Array[(DiffOp, Int, Int)] = []
  for line in result.lines {
    summary.push((line.op, line.old_line_no, line.new_line_no))
  }
  summary
}

///|
/// 统计差异行数
pub fn count_diff(result : DiffResult) -> (Int, Int, Int) {
  (result.added, result.deleted, result.changed)
}

///|
/// 比较两个文件的差异并输出
pub async fn run_diff(matches : @argparse.Matches) -> Unit {
  let old_file = get_positional(matches.values, "file1", "")
  let new_file = get_positional(matches.values, "file2", "")
  if old_file.length() == 0 || new_file.length() == 0 {
    @stdio.stdout.write("Usage: moonsh diff <file1> <file2>\n")
    return
  }
  let old_text = @fs.read_file(old_file).text()
  let new_text = @fs.read_file(new_file).text()
  let result = diff_text(old_text, new_text)
  let use_color = get_flag(matches.flags, "color")
  let output = if use_color {
    format_diff_colored(result)
  } else {
    format_diff(result)
  }
  @stdio.stdout.write(output)
}
