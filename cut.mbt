// cut.mbt — cut 命令：从每行中提取字段或字符
// 支持：按分隔符提取字段、按字符位置提取、按字节提取

///|
/// cut 模式
pub enum CutMode {
  /// 按分隔符提取字段
  Field(String, Array[(Int, Int)])
  /// 按字符位置提取
  CharPositions(Array[(Int, Int)])
  /// 按字节位置提取
  BytePositions(Array[(Int, Int)])
}

///|
/// 解析位置范围字符串 "1-3,5,7-9" -> [(1,3),(5,5),(7,9)]
pub fn parse_positions(spec : String) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  let fields = split_by_char(spec, ',')
  for field in fields {
    match field.find("-") {
      Some(dash_pos) => {
        let start_str = field.substring(start=0, end=dash_pos)
        let end_str = field.substring(start=dash_pos + 1)
        let start = if start_str.length() == 0 {
          1
        } else {
          parse_int_safe(start_str, 1)
        }
        let end = if end_str.length() == 0 {
          999999
        } else {
          parse_int_safe(end_str, start)
        }
        result.push((start, end))
      }
      None => {
        let n = parse_int_safe(field, 1)
        result.push((n, n))
      }
    }
  }
  result
}

///|
/// 按字符分割字符串
fn split_by_char(s : String, sep : Char) -> Array[String] {
  let result : Array[String] = []
  let buf = StringBuilder::new()
  for c in s.iter() {
    if c == sep {
      result.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(c)
    }
  }
  result.push(buf.to_string())
  result
}

///|
/// 按分隔符分割行
fn split_line_by_delimiter(line : String, delim : String) -> Array[String] {
  if delim.length() == 0 {
    return [line]
  }
  let result : Array[String] = []
  let buf = StringBuilder::new()
  let chars = line.to_array()
  let delim_chars = delim.to_array()
  let delim_len = delim_chars.length()
  let mut i = 0
  while i < chars.length() {
    let mut matched = true
    let mut j = 0
    while j < delim_len {
      if i + j >= chars.length() || chars[i + j] != delim_chars[j] {
        matched = false
        break
      }
      j = j + 1
    }
    if matched && delim_len > 0 {
      result.push(buf.to_string())
      buf.reset()
      i = i + delim_len
    } else {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  result.push(buf.to_string())
  result
}

///|
/// 从行中提取字段
fn extract_fields(
  line : String,
  positions : Array[(Int, Int)],
  delimiter : String,
) -> String {
  let fields = split_line_by_delimiter(line, delimiter)
  let buf = StringBuilder::new()
  let mut first = true
  for entry in positions {
    // 转为 0-based
    let (start, end) = entry
    let s = start - 1
    let e = end - 1
    let mut i = s
    while i <= e && i < fields.length() {
      if not(first) {
        buf.write_string(delimiter)
      }
      buf.write_string(fields[i])
      first = false
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// 从行中提取字符位置
fn extract_chars(line : String, positions : Array[(Int, Int)]) -> String {
  let chars = line.to_array()
  let buf = StringBuilder::new()
  for entry in positions {
    let (start, end) = entry
    let s = start - 1
    let e = end - 1
    let mut i = s
    while i <= e && i < chars.length() {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// 从行中提取字节位置（简化版：ASCII 等价于字符位置）
fn extract_bytes(line : String, positions : Array[(Int, Int)]) -> String {
  // 对于纯 ASCII 文本，字节位置 = 字符位置
  extract_chars(line, positions)
}

///|
/// 从行中提取内容
pub fn cut_line(line : String, mode : CutMode) -> String {
  match mode {
    Field(delim, positions) => extract_fields(line, positions, delim)
    CharPositions(positions) => extract_chars(line, positions)
    BytePositions(positions) => extract_bytes(line, positions)
  }
}

///|
/// 对多行执行 cut
pub fn cut_lines(lines : Array[String], mode : CutMode) -> Array[String] {
  let result : Array[String] = []
  for line in lines {
    result.push(cut_line(line, mode))
  }
  result
}

///|
/// 运行 cut 命令
pub async fn run_cut(matches : @argparse.Matches) -> Unit {
  let lines : Array[String] = []
  let file_path = get_positional(matches.values, "file", "")
  // 读取输入
  if file_path.length() > 0 && file_path != "-" {
    let content = @fs.read_file(file_path).text()
    for line in split_lines(content) {
      lines.push(line)
    }
  } else {
    let input = @stdio.stdin.read_all().text()
    for line in split_lines(input) {
      lines.push(line)
    }
  }
  // 确定模式
  let delim = get_option(matches.values, "delimiter")
  let fields_spec = get_option(matches.values, "fields")
  let chars_spec = get_option(matches.values, "characters")
  let bytes_spec = get_option(matches.values, "bytes")
  let mode : CutMode = if fields_spec.length() > 0 {
    let d = if delim.length() > 0 { delim } else { "\t" }
    Field(d, parse_positions(fields_spec))
  } else if chars_spec.length() > 0 {
    CharPositions(parse_positions(chars_spec))
  } else if bytes_spec.length() > 0 {
    BytePositions(parse_positions(bytes_spec))
  } else {
    // 默认按字段模式
    Field("\t", parse_positions("1-"))
  }
  let result = cut_lines(lines, mode)
  let buf = StringBuilder::new()
  for line in result {
    buf.write_string(line)
    buf.write_char('\n')
  }
  @stdio.stdout.write(buf.to_string())
}
