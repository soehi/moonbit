// uniq.mbt — uniq 命令：去除相邻重复行
// 支持：只显示重复行、只显示唯一行、计数、忽略大小写

///|
/// uniq 选项
pub struct UniqOptions {
  /// 只显示重复行
  only_duplicate : Bool
  /// 只显示唯一行（不重复的）
  only_unique : Bool
  /// 显示计数
  count : Bool
  /// 忽略大小写
  ignore_case : Bool
  /// 跳过前 N 个字段
  skip_fields : Int
  /// 跳过前 N 个字符
  skip_chars : Int
}

///|
/// 默认 uniq 选项
pub fn UniqOptions::default() -> UniqOptions {
  {
    only_duplicate: false,
    only_unique: false,
    count: false,
    ignore_case: false,
    skip_fields: 0,
    skip_chars: 0,
  }
}

///|
/// 去除相邻重复行
pub fn uniq_lines(
  lines : Array[String],
  options : UniqOptions,
) -> Array[String] {
  simple_adjacent_uniq(lines, options)
}

///|
/// 构建去重比较键
fn build_uniq_key(line : String, options : UniqOptions) -> String {
  let mut key = line
  // 跳过字段
  if options.skip_fields > 0 {
    key = skip_fields_impl(key, options.skip_fields)
  }
  // 跳过字符
  if options.skip_chars > 0 {
    let chars = key.to_array()
    let skip = if options.skip_chars < chars.length() {
      options.skip_chars
    } else {
      chars.length()
    }
    key = key.substring(start=skip)
  }
  // 忽略大小写
  if options.ignore_case {
    key = key.to_lower()
  }
  key
}

///|
/// 跳过前 N 个字段（空格分隔）
fn skip_fields_impl(s : String, n : Int) -> String {
  let mut skip_count = 0
  let mut i = 0
  let chars = s.to_array()
  let len = chars.length()
  // 跳过前导空白
  while i < len && (chars[i] == ' ' || chars[i] == '\t') {
    i = i + 1
  }
  while skip_count < n && i < len {
    // 跳过一个字段
    while i < len && chars[i] != ' ' && chars[i] != '\t' {
      i = i + 1
    }
    // 跳过空白
    while i < len && (chars[i] == ' ' || chars[i] == '\t') {
      i = i + 1
    }
    skip_count = skip_count + 1
  }
  if i < len {
    s.substring(start=i)
  } else {
    ""
  }
}

///|
/// 判断一组是否应该输出
fn should_output_group(count : Int, options : UniqOptions) -> Bool {
  if options.only_unique {
    count == 1
  } else if options.only_duplicate {
    count > 1
  } else {
    true
  }
}

///|
/// 运行 uniq 命令
pub async fn run_uniq(matches : @argparse.Matches) -> Unit {
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
  // 构建选项
  let skip_fields_str = get_option(matches.values, "skip_fields")
  let skip_chars_str = get_option(matches.values, "skip_chars")
  let options : UniqOptions = {
    only_duplicate: get_flag(matches.flags, "repeated"),
    only_unique: get_flag(matches.flags, "unique"),
    count: get_flag(matches.flags, "count"),
    ignore_case: get_flag(matches.flags, "ignore_case"),
    skip_fields: if skip_fields_str.length() > 0 {
      parse_int_safe(skip_fields_str, 0)
    } else {
      0
    },
    skip_chars: if skip_chars_str.length() > 0 {
      parse_int_safe(skip_chars_str, 0)
    } else {
      0
    },
  }
  // 使用简单的相邻去重
  let result = simple_adjacent_uniq(lines, options)
  let buf = StringBuilder::new()
  for line in result {
    buf.write_string(line)
    buf.write_char('\n')
  }
  @stdio.stdout.write(buf.to_string())
}

///|
/// 简单的相邻去重（直接实现）
fn simple_adjacent_uniq(
  lines : Array[String],
  options : UniqOptions,
) -> Array[String] {
  if lines.is_empty() {
    return []
  }
  let result : Array[String] = []
  let mut prev_key = ""
  let mut prev_line = ""
  let mut count = 0
  let mut first = true
  for line in lines {
    let key = build_uniq_key(line, options)
    if first {
      prev_key = key
      prev_line = line
      count = 1
      first = false
    } else if key == prev_key {
      count = count + 1
    } else {
      // 输出前一组
      if should_output_group(count, options) {
        if options.count {
          result.push(pad_left(count.to_string(), 7) + " " + prev_line)
        } else {
          result.push(prev_line)
        }
      }
      prev_key = key
      prev_line = line
      count = 1
    }
  }
  // 输出最后一组
  if should_output_group(count, options) {
    if options.count {
      result.push(pad_left(count.to_string(), 7) + " " + prev_line)
    } else {
      result.push(prev_line)
    }
  }
  result
}
