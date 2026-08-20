// sort.mbt — sort 命令：文本行排序
// 支持：数值排序、字典序排序、逆序、去重、按字段排序

///|
/// 排序模式
pub enum SortMode {
  /// 字典序（默认）
  Lexical
  /// 数值排序
  Numeric
  /// 自然排序（数字部分按大小）
  Natural
  /// 按月份名排序
  MonthName
  /// 按版本号排序
  Version
}

///|
/// 排序选项
pub struct SortOptions {
  /// 排序模式
  mode : SortMode
  /// 逆序
  reverse : Bool
  /// 去重
  unique : Bool
  /// 忽略大小写
  ignore_case : Bool
  /// 忽略前导空白
  ignore_blanks : Bool
  /// 按字段排序（0-based 索引）
  key_field : Int?
  /// 字段分隔符
  field_separator : String
}

///|
/// 默认排序选项
pub fn SortOptions::default() -> SortOptions {
  {
    mode: Lexical,
    reverse: false,
    unique: false,
    ignore_case: false,
    ignore_blanks: false,
    key_field: None,
    field_separator: " ",
  }
}

///|
/// 排序文本行
pub fn sort_lines(
  lines : Array[String],
  options : SortOptions,
) -> Array[String] {
  // 预处理：应用 ignore_case 和 ignore_blanks
  let processed : Array[(String, String)] = [] // (key, original)
  for line in lines {
    let key = extract_sort_key(line, options)
    processed.push((key, line))
  }
  // 排序
  let sorted = sort_with_key(processed, options)
  // 去重
  let result : Array[String] = []
  let mut prev_key : String = ""
  for entry in sorted {
    let (key, line) = entry
    if options.unique {
      if key == prev_key {
        continue
      }
      prev_key = key
    }
    result.push(line)
  }
  result
}

///|
/// 提取排序键
fn extract_sort_key(line : String, options : SortOptions) -> String {
  let mut key = line
  // 忽略前导空白
  if options.ignore_blanks {
    key = strip_leading_whitespace(key)
  }
  // 提取字段
  match options.key_field {
    Some(field_idx) =>
      key = extract_field(key, field_idx, options.field_separator)
    None => ()
  }
  // 忽略大小写
  if options.ignore_case {
    key = key.to_lower()
  }
  key
}

///|
/// 去除前导空白
fn strip_leading_whitespace(s : String) -> String {
  let mut start = 0
  while start < s.length() {
    let c = s[start]
    if c != ' ' && c != '\t' {
      break
    }
    start = start + 1
  }
  if start == 0 {
    s
  } else {
    s.substring(start~)
  }
}

///|
/// 提取指定字段
fn extract_field(line : String, field_idx : Int, separator : String) -> String {
  if separator == " " {
    // 空格分隔：连续空格视为一个分隔符
    let fields = split_by_whitespace(line)
    if field_idx >= 0 && field_idx < fields.length() {
      fields[field_idx]
    } else {
      ""
    }
  } else {
    let fields = split_by_separator(line, separator)
    if field_idx >= 0 && field_idx < fields.length() {
      fields[field_idx]
    } else {
      ""
    }
  }
}

///|
/// 按空白分割
fn split_by_whitespace(s : String) -> Array[String] {
  let result : Array[String] = []
  let buf = StringBuilder::new()
  let mut in_word = false
  for c in s.iter() {
    if c == ' ' || c == '\t' {
      if in_word {
        result.push(buf.to_string())
        buf.reset()
        in_word = false
      }
    } else {
      buf.write_char(c)
      in_word = true
    }
  }
  if in_word {
    result.push(buf.to_string())
  }
  result
}

///|
/// 按分隔符分割
fn split_by_separator(s : String, sep : String) -> Array[String] {
  let result : Array[String] = []
  let buf = StringBuilder::new()
  let sep_chars = sep.to_array()
  let sep_len = sep_chars.length()
  let s_chars = s.to_array()
  let mut i = 0
  while i < s_chars.length() {
    let mut match_pos = true
    let mut j = 0
    while j < sep_len {
      if i + j >= s_chars.length() {
        match_pos = false
        break
      }
      if s_chars[i + j] != sep_chars[j] {
        match_pos = false
        break
      }
      j = j + 1
    }
    if match_pos {
      result.push(buf.to_string())
      buf.reset()
      i = i + sep_len
    } else {
      buf.write_char(s_chars[i])
      i = i + 1
    }
  }
  result.push(buf.to_string())
  result
}

///|
/// 排序（带 key 比较）
fn sort_with_key(
  arr : Array[(String, String)],
  options : SortOptions,
) -> Array[(String, String)] {
  // 简单冒泡排序（MoonBit 没有内置 sort）
  let result : Array[(String, String)] = []
  for item in arr {
    result.push(item)
  }
  let n = result.length()
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      let should_swap = compare_keys(result[j].0, result[j + 1].0, options) > 0
      if should_swap {
        let tmp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = tmp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

///|
/// 比较两个排序键
/// 返回: 负数 a<b, 0 相等, 正数 a>b
fn compare_keys(a : String, b : String, options : SortOptions) -> Int {
  let cmp = match options.mode {
    Lexical => compare_lexical(a, b)
    Numeric => compare_numeric(a, b)
    Natural => compare_natural(a, b)
    MonthName => compare_month(a, b)
    Version => compare_version(a, b)
  }
  if options.reverse {
    -cmp
  } else {
    cmp
  }
}

///|
/// 字典序比较
fn compare_lexical(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let min_len = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  let mut i = 0
  while i < min_len {
    let ac = a_chars[i].to_int()
    let bc = b_chars[i].to_int()
    if ac < bc {
      return -1
    }
    if ac > bc {
      return 1
    }
    i = i + 1
  }
  if a_chars.length() < b_chars.length() {
    -1
  } else if a_chars.length() > b_chars.length() {
    1
  } else {
    0
  }
}

///|
/// 数值比较
fn compare_numeric(a : String, b : String) -> Int {
  let na = parse_number_prefix(a)
  let nb = parse_number_prefix(b)
  if na < nb {
    -1
  } else if na > nb {
    1
  } else {
    compare_lexical(a, b)
  }
}

///|
/// 自然排序比较（数字部分按大小）
fn compare_natural(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let mut ai = 0
  let mut bi = 0
  while ai < a_chars.length() && bi < b_chars.length() {
    let ac = a_chars[ai]
    let bc = b_chars[bi]
    // 如果都是数字，提取连续数字段进行比较
    if is_digit(ac) && is_digit(bc) {
      // 提取 a 的数字段
      let a_start = ai
      while ai < a_chars.length() && is_digit(a_chars[ai]) {
        ai = ai + 1
      }
      let b_start = bi
      while bi < b_chars.length() && is_digit(b_chars[bi]) {
        bi = bi + 1
      }
      // 去前导零后比较
      let a_num_str = a.substring(start=a_start, end=ai)
      let b_num_str = b.substring(start=b_start, end=bi)
      let a_stripped = strip_leading_zeros(a_num_str)
      let b_stripped = strip_leading_zeros(b_num_str)
      // 先比长度
      if a_stripped.length() < b_stripped.length() {
        return -1
      }
      if a_stripped.length() > b_stripped.length() {
        return 1
      }
      // 长度相同，逐字符比较
      let cmp = compare_lexical(a_stripped, b_stripped)
      if cmp != 0 {
        return cmp
      }
    } else {
      let ac_int = ac.to_int()
      let bc_int = bc.to_int()
      if ac_int < bc_int {
        return -1
      }
      if ac_int > bc_int {
        return 1
      }
      ai = ai + 1
      bi = bi + 1
    }
  }
  if ai >= a_chars.length() && bi >= b_chars.length() {
    0
  } else if ai >= a_chars.length() {
    -1
  } else {
    1
  }
}

///|
/// 月份名比较
fn compare_month(a : String, b : String) -> Int {
  let ma = parse_month(a)
  let mb = parse_month(b)
  if ma < mb {
    -1
  } else if ma > mb {
    1
  } else {
    0
  }
}

///|
/// 版本号比较
fn compare_version(a : String, b : String) -> Int {
  let a_parts = split_by_separator(a, ".")
  let b_parts = split_by_separator(b, ".")
  let max_len = if a_parts.length() > b_parts.length() {
    a_parts.length()
  } else {
    b_parts.length()
  }
  let mut i = 0
  while i < max_len {
    let a_val = if i < a_parts.length() {
      parse_number_prefix(a_parts[i])
    } else {
      0
    }
    let b_val = if i < b_parts.length() {
      parse_number_prefix(b_parts[i])
    } else {
      0
    }
    if a_val < b_val {
      return -1
    }
    if a_val > b_val {
      return 1
    }
    i = i + 1
  }
  0
}

///|
/// 解析字符串开头的数字
fn parse_number_prefix(s : String) -> Int {
  let buf = StringBuilder::new()
  let mut found_sign = false
  let mut found_digit = false
  for c in s.iter() {
    if c == '-' && not(found_sign) && not(found_digit) {
      buf.write_char(c)
      found_sign = true
    } else if c == '+' && not(found_sign) && not(found_digit) {
      found_sign = true
    } else if is_digit(c) {
      buf.write_char(c)
      found_digit = true
    } else {
      break
    }
  }
  if found_digit {
    parse_int_safe(buf.to_string(), 0)
  } else {
    0
  }
}

///|
/// 去除前导零
fn strip_leading_zeros(s : String) -> String {
  let mut start = 0
  while start < s.length() - 1 {
    let c = s[start]
    if c != '0' {
      break
    }
    start = start + 1
  }
  s.substring(start~)
}

///|
/// 解析月份名（返回 1-12，0 表示未知）
fn parse_month(s : String) -> Int {
  let lower = s.to_lower()
  match lower {
    "jan" | "january" => 1
    "feb" | "february" => 2
    "mar" | "march" => 3
    "apr" | "april" => 4
    "may" => 5
    "jun" | "june" => 6
    "jul" | "july" => 7
    "aug" | "august" => 8
    "sep" | "sept" | "september" => 9
    "oct" | "october" => 10
    "nov" | "november" => 11
    "dec" | "december" => 12
    _ => 0
  }
}

///|
/// 运行 sort 命令
pub async fn run_sort(matches : @argparse.Matches) -> Unit {
  let lines : Array[String] = []
  let file_path = get_positional(matches.values, "file", "")
  let opt = get_option(matches.values, "lines")
  let _n = if opt.length() > 0 { parse_int_safe(opt, 10) } else { 10 }
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
  // 构建排序选项
  let options : SortOptions = {
    mode: if get_flag(matches.flags, "numeric") {
      Numeric
    } else if get_flag(matches.flags, "natural") {
      Natural
    } else if get_flag(matches.flags, "version") {
      Version
    } else {
      Lexical
    },
    reverse: get_flag(matches.flags, "reverse"),
    unique: get_flag(matches.flags, "unique"),
    ignore_case: get_flag(matches.flags, "ignore_case"),
    ignore_blanks: get_flag(matches.flags, "ignore_blanks"),
    key_field: match get_option(matches.values, "key").length() {
      0 => None
      _ => Some(parse_int_safe(get_option(matches.values, "key"), 0))
    },
    field_separator: get_option(matches.values, "separator"),
  }
  let sorted = sort_lines(lines, options)
  let buf = StringBuilder::new()
  for line in sorted {
    buf.write_string(line)
    buf.write_char('\n')
  }
  @stdio.stdout.write(buf.to_string())
}
