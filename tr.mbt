// tr.mbt — tr 命令：字符转换/删除/压缩
// 支持：字符集转换、删除指定字符、压缩重复字符、大小写转换

///|
/// tr 选项
pub struct TrOptions {
  /// 删除指定字符
  delete : Bool
  /// 压缩重复字符
  squeeze : Bool
  /// 反转字符集（配合 -d 使用）
  complement : Bool
  /// 截断模式：只替换第一组匹配
  truncate : Bool
}

///|
/// 默认 tr 选项
pub fn TrOptions::default() -> TrOptions {
  { delete: false, squeeze: false, complement: false, truncate: false }
}

///|
/// 字符集
pub struct CharSet {
  /// 字符列表
  chars : Array[Char]
  /// 是否为范围集（如 a-z）
  ranges : Array[(Char, Char)]
}

///|
/// 解析字符集规范
/// 支持的语法：
///   a-z: 范围
///   abc: 单个字符
///   \n: 换行
///   \t: 制表符
///   \\: 反斜杠
///   [abc]: 集合
///   [a-z]: 范围集合
///   [:alpha:]: POSIX 类
pub fn parse_charset(spec : String) -> CharSet {
  let chars : Array[Char] = []
  let ranges : Array[(Char, Char)] = []
  let spec_chars = spec.to_array()
  let mut i = 0
  while i < spec_chars.length() {
    let c = spec_chars[i]
    if c == '\\' && i + 1 < spec_chars.length() {
      // 转义字符
      let next = spec_chars[i + 1]
      let escaped = match next {
        'n' => '\n'
        't' => '\t'
        'r' => '\r'
        '\\' => '\\'
        '0' => '\u{0}'
        'a' => '\u{7}'
        'b' => '\u{8}'
        'f' => '\u{c}'
        'v' => '\u{b}'
        _ => next
      }
      chars.push(escaped)
      i = i + 2
    } else if c == '[' && i + 1 < spec_chars.length() {
      // POSIX 字符类 [:alpha:] 等
      if spec_chars[i + 1] == ':' {
        let (posix_chars, next_i) = parse_posix_class(spec_chars, i)
        for pc in posix_chars {
          chars.push(pc)
        }
        i = next_i
      } else {
        chars.push(c)
        i = i + 1
      }
    } else if i + 2 < spec_chars.length() && spec_chars[i + 1] == '-' {
      // 范围 a-z
      ranges.push((c, spec_chars[i + 2]))
      i = i + 3
    } else {
      chars.push(c)
      i = i + 1
    }
  }
  { chars, ranges }
}

///|
/// 解析 POSIX 字符类
fn parse_posix_class(chars : Array[Char], start : Int) -> (Array[Char], Int) {
  // 查找 :]
  let mut end = start + 2
  while end < chars.length() {
    if chars[end] == ':' && end + 1 < chars.length() && chars[end + 1] == ']' {
      break
    }
    end = end + 1
  }
  if end >= chars.length() {
    return ([chars[start]], start + 1)
  }
  // 提取类名
  let sub : Array[Char] = []
  let mut k = start + 2
  while k < end {
    sub.push(chars[k])
    k = k + 1
  }
  let class_name_buf = StringBuilder::new()
  for sc in sub {
    class_name_buf.write_char(sc)
  }
  let class_name = class_name_buf.to_string()
  let result : Array[Char] = []
  match class_name {
    "alpha" => {
      let mut c = 'a'
      while c <= 'z' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
      let mut c2 = 'A'
      while c2 <= 'Z' {
        result.push(c2)
        c2 = Int::unsafe_to_char(c2.to_int() + 1)
      }
    }
    "digit" => {
      let mut c = '0'
      while c <= '9' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
    }
    "alnum" => {
      let mut c = 'a'
      while c <= 'z' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
      let mut c2 = 'A'
      while c2 <= 'Z' {
        result.push(c2)
        c2 = Int::unsafe_to_char(c2.to_int() + 1)
      }
      let mut c3 = '0'
      while c3 <= '9' {
        result.push(c3)
        c3 = Int::unsafe_to_char(c3.to_int() + 1)
      }
    }
    "upper" => {
      let mut c = 'A'
      while c <= 'Z' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
    }
    "lower" => {
      let mut c = 'a'
      while c <= 'z' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
    }
    "space" => {
      result.push(' ')
      result.push('\t')
      result.push('\n')
      result.push('\r')
    }
    "punct" => {
      result.push('!')
      result.push('"')
      result.push('#')
      result.push('$')
      result.push('%')
      result.push('&')
      result.push('\'')
      result.push('(')
      result.push(')')
      result.push('*')
      result.push('+')
      result.push(',')
      result.push('-')
      result.push('.')
      result.push('/')
      result.push(':')
      result.push(';')
      result.push('<')
      result.push('=')
      result.push('>')
      result.push('?')
      result.push('@')
      result.push('[')
      result.push(']')
      result.push('^')
      result.push('_')
      result.push('`')
      result.push('{')
      result.push('|')
      result.push('}')
      result.push('~')
    }
    "blank" => {
      result.push(' ')
      result.push('\t')
    }
    "print" => {
      let mut c = ' '
      while c <= '~' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
    }
    "cntrl" => {
      let mut i = 0
      while i < 32 {
        result.push(Int::unsafe_to_char(i))
        i = i + 1
      }
      result.push(Int::unsafe_to_char(127))
    }
    "xdigit" => {
      let mut c = '0'
      while c <= '9' {
        result.push(c)
        c = Int::unsafe_to_char(c.to_int() + 1)
      }
      let mut c2 = 'a'
      while c2 <= 'f' {
        result.push(c2)
        c2 = Int::unsafe_to_char(c2.to_int() + 1)
      }
      let mut c3 = 'A'
      while c3 <= 'F' {
        result.push(c3)
        c3 = Int::unsafe_to_char(c3.to_int() + 1)
      }
    }
    _ => ()
  }
  (result, end + 2)
}

///|
/// 检查字符是否在字符集中
pub fn char_in_set(c : Char, set : CharSet) -> Bool {
  // 检查单字符列表
  for ch in set.chars {
    if c == ch {
      return true
    }
  }
  // 检查范围
  for entry in set.ranges {
    let (lo, hi) = entry
    if c >= lo && c <= hi {
      return true
    }
  }
  false
}

///|
/// 获取字符集中的第 n 个字符
fn char_at_index(set : CharSet, idx : Int) -> Char? {
  let mut count = 0
  // 先遍历单字符
  for c in set.chars {
    if count == idx {
      return Some(c)
    }
    count = count + 1
  }
  // 再遍历范围
  for entry in set.ranges {
    let (lo, hi) = entry
    let mut c = lo
    while c <= hi {
      if count == idx {
        return Some(c)
      }
      count = count + 1
      c = Int::unsafe_to_char(c.to_int() + 1)
    }
  }
  None
}

///|
/// 字符集大小
pub fn charset_size(set : CharSet) -> Int {
  let mut count = set.chars.length()
  for entry in set.ranges {
    let (lo, hi) = entry
    count = count + (hi.to_int() - lo.to_int() + 1)
  }
  count
}

///|
/// 转换文本
pub fn tr_translate(
  input : String,
  from_set : CharSet,
  to_set : CharSet,
  options : TrOptions,
) -> String {
  if options.delete {
    return tr_delete(input, from_set, options.complement)
  }
  let buf = StringBuilder::new()
  let to_size = charset_size(to_set)
  let input_chars = input.to_array()
  let mut i = 0
  while i < input_chars.length() {
    let c = input_chars[i]
    if char_in_set(c, from_set) {
      // 查找在 from_set 中的位置
      let pos = char_index_in_set(c, from_set)
      match pos {
        Some(idx) =>
          if to_size > 0 {
            let mapped_idx = idx % to_size
            match char_at_index(to_set, mapped_idx) {
              Some(replacement) => buf.write_char(replacement)
              None => buf.write_char(c)
            }
          } else {
            buf.write_char(c)
          }
        None => buf.write_char(c)
      }
    } else {
      buf.write_char(c)
    }
    i = i + 1
  }
  let result = buf.to_string()
  if options.squeeze {
    tr_squeeze(result, from_set, to_set, options)
  } else {
    result
  }
}

///|
/// 删除字符集中的字符
fn tr_delete(input : String, set : CharSet, complement : Bool) -> String {
  let buf = StringBuilder::new()
  for c in input.iter() {
    let in_set = char_in_set(c, set)
    if complement {
      // -c -d: 删除不在集合中的字符
      if in_set {
        buf.write_char(c)
      }
      // -d: 删除在集合中的字符
    } else if !in_set {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// 压缩重复字符
fn tr_squeeze(
  input : String,
  from_set : CharSet,
  to_set : CharSet,
  options : TrOptions,
) -> String {
  let buf = StringBuilder::new()
  let input_chars = input.to_array()
  let mut prev_char : Char = '\u{0}'
  let mut first = true
  let mut i = 0
  while i < input_chars.length() {
    let c = input_chars[i]
    // 检查这个字符是否是 squeeze 目标
    let is_squeeze_target = if options.complement {
      !char_in_set(c, from_set)
    } else {
      char_in_set(c, from_set) || char_in_set(c, to_set)
    }
    if is_squeeze_target && not(first) && c == prev_char {
      // 跳过重复字符
      i = i + 1
      continue
    }
    buf.write_char(c)
    prev_char = c
    first = false
    i = i + 1
  }
  buf.to_string()
}

///|
/// 查找字符在字符集中的索引
fn char_index_in_set(c : Char, set : CharSet) -> Int? {
  let mut idx = 0
  // 先遍历单字符
  for ch in set.chars {
    if c == ch {
      return Some(idx)
    }
    idx = idx + 1
  }
  // 再遍历范围
  for entry in set.ranges {
    let (lo, hi) = entry
    if c >= lo && c <= hi {
      return Some(idx + (c.to_int() - lo.to_int()))
    }
    idx = idx + (hi.to_int() - lo.to_int() + 1)
  }
  None
}

///|
/// 运行 tr 命令
pub async fn run_tr(matches : @argparse.Matches) -> Unit {
  // 获取位置参数
  let set1 = get_positional(matches.values, "set1", "")
  let set2 = get_positional(matches.values, "set2", "")
  // 构建选项
  let options : TrOptions = {
    delete: get_flag(matches.flags, "delete"),
    squeeze: get_flag(matches.flags, "squeeze"),
    complement: get_flag(matches.flags, "complement"),
    truncate: get_flag(matches.flags, "truncate"),
  }
  // 读取 stdin
  let input = @stdio.stdin.read_all().text()
  let from_set = parse_charset(set1)
  let to_set = parse_charset(set2)
  let result = tr_translate(input, from_set, to_set, options)
  @stdio.stdout.write(result)
}
