// moonsh.mbt — moonsh 现代化 Shell 命令行工具集
// 公共工具模块：颜色输出、格式化辅助、文件类型检测

///|
/// ANSI 颜色码
pub enum Color {
  Reset
  Bold
  Dim
  Italic
  Underline
  Red
  Green
  Yellow
  Blue
  Magenta
  Cyan
  White
  BrightBlack
  BrightRed
  BrightGreen
  BrightYellow
  BrightBlue
  BrightMagenta
  BrightCyan
  BrightWhite
}

///|
/// 将颜色转为 ANSI 转义序列
pub fn Color::to_ansi(self : Color) -> String {
  match self {
    Reset => "\u{1b}[0m"
    Bold => "\u{1b}[1m"
    Dim => "\u{1b}[2m"
    Italic => "\u{1b}[3m"
    Underline => "\u{1b}[4m"
    Red => "\u{1b}[31m"
    Green => "\u{1b}[32m"
    Yellow => "\u{1b}[33m"
    Blue => "\u{1b}[34m"
    Magenta => "\u{1b}[35m"
    Cyan => "\u{1b}[36m"
    White => "\u{1b}[37m"
    BrightBlack => "\u{1b}[90m"
    BrightRed => "\u{1b}[91m"
    BrightGreen => "\u{1b}[92m"
    BrightYellow => "\u{1b}[93m"
    BrightBlue => "\u{1b}[94m"
    BrightMagenta => "\u{1b}[95m"
    BrightCyan => "\u{1b}[96m"
    BrightWhite => "\u{1b}[97m"
  }
}

///|
/// 用颜色包裹文本（单色）
pub fn colorize(text : String, color : Color) -> String {
  color.to_ansi() + text + Color::Reset.to_ansi()
}

///|
/// 用多个颜色样式包裹文本
pub fn colorize_multi(text : String, colors : Array[Color]) -> String {
  let prefix = StringBuilder::new()
  for c in colors {
    prefix.write_string(c.to_ansi())
  }
  prefix.write_string(text)
  prefix.write_string(Color::Reset.to_ansi())
  prefix.to_string()
}

///|
/// 终端颜色支持检测
pub struct TermConfig {
  color_enabled : Bool
  width : Int
}

///|
/// 默认终端配置
pub fn TermConfig::default() -> TermConfig {
  { color_enabled: true, width: 80 }
}

///|
/// 文件大小人类可读格式化
/// 1024 -> "1.0 KiB", 1048576 -> "1.0 MiB"
pub fn format_size(bytes : Int64) -> String {
  let units = ["B", "KiB", "MiB", "GiB", "TiB"]
  let mut size = bytes.to_double()
  let mut idx = 0
  while idx < 4 && size >= 1024.0 {
    size = size / 1024.0
    idx = idx + 1
  }
  if idx == 0 {
    "\{bytes} \{units[idx]}"
  } else {
    // 保留一位小数
    let s = size.to_string()
    let dot = s.find(".")
    match dot {
      Some(d) => "\{s[:d + 2].to_owned()} \{units[idx]}"
      None => "\{s}.0 \{units[idx]}"
    }
  }
}

///|
/// 文件大小人类可读格式化（Int 版本）
pub fn format_size_int(bytes : Int) -> String {
  format_size(bytes.to_int64())
}

///|
/// 文件类型枚举
pub enum FileType {
  Regular
  Directory
  Symlink
  Executable
  Archive
  Image
  Code
  Doc
  Audio
  Video
  Other
}

///|
/// 根据文件名扩展名推断文件类型
pub fn detect_file_type(filename : String) -> FileType {
  let ext = get_extension(filename)
  match ext {
    "" => Regular
    "tar" | "gz" | "zip" | "rar" | "7z" | "bz2" | "xz" | "tgz" => Archive
    "png"
    | "jpg"
    | "jpeg"
    | "gif"
    | "bmp"
    | "svg"
    | "webp"
    | "ico"
    | "tiff"
    | "raw" => Image
    "mp3" | "wav" | "flac" | "ogg" | "aac" | "m4a" => Audio
    "mp4" | "avi" | "mkv" | "mov" | "wmv" | "flv" | "webm" => Video
    "md" | "txt" | "pdf" | "doc" | "docx" | "rst" | "rtf" | "odt" => Doc
    "mbt"
    | "moonbit"
    | "rs"
    | "go"
    | "py"
    | "js"
    | "ts"
    | "jsx"
    | "tsx"
    | "java"
    | "c"
    | "cpp"
    | "cc"
    | "h"
    | "hpp"
    | "cs"
    | "rb"
    | "swift"
    | "kt"
    | "scala"
    | "lua"
    | "sh"
    | "bash"
    | "zsh"
    | "fish"
    | "ps1"
    | "vim"
    | "elm"
    | "clj"
    | "ex"
    | "exs"
    | "erl"
    | "hs"
    | "ml"
    | "nim"
    | "ocaml"
    | "perl"
    | "php"
    | "r"
    | "dart"
    | "gradle"
    | "xml"
    | "yml"
    | "yaml"
    | "toml"
    | "json"
    | "json5"
    | "jsonc" => Code
    _ => Other
  }
}

///|
/// 获取文件扩展名（小写，不含点）
pub fn get_extension(filename : String) -> String {
  let base = get_basename_from_path(filename)
  match base.rev_find(".") {
    Some(dot_pos) =>
      if dot_pos == 0 || dot_pos == base.length() - 1 {
        ""
      } else {
        base.sub(start=dot_pos + 1).to_owned().to_lower()
      }
    None => ""
  }
}

///|
/// 从路径中提取文件名部分（去掉目录前缀）
pub fn get_basename_from_path(path : String) -> String {
  match path.rev_find("/") {
    Some(pos) => path.sub(start=pos + 1).to_owned()
    None =>
      match path.rev_find("\\") {
        Some(pos) => path.sub(start=pos + 1).to_owned()
        None => path
      }
  }
}

///|
/// 获取不含扩展名的文件名
pub fn get_basename(filename : String) -> String {
  let base = get_basename_from_path(filename)
  match base.rev_find(".") {
    Some(dot_pos) =>
      if dot_pos <= 0 {
        base
      } else {
        base.sub(start=0, end=dot_pos).to_owned()
      }
    None => base
  }
}

///|
/// 获取路径的目录部分
pub fn get_dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(pos) =>
      if pos == 0 {
        "/"
      } else {
        path.sub(start=0, end=pos).to_owned()
      }
    None =>
      match path.rev_find("\\") {
        Some(pos) => path.sub(start=0, end=pos).to_owned()
        None => "."
      }
  }
}

///|
/// 根据文件类型返回颜色
pub fn file_type_color(ft : FileType) -> Color {
  match ft {
    Directory => Blue
    Executable => Green
    Archive => Red
    Image => Magenta
    Audio => BrightMagenta
    Video => BrightMagenta
    Code => Cyan
    Doc => Yellow
    Regular | Other | Symlink => White
  }
}

///|
/// 根据文件类型返回图标
pub fn file_type_icon(ft : FileType) -> String {
  match ft {
    Directory => "\u{1f4c1}"
    Regular => "\u{1f4c4}"
    Executable => "\u{26a1}"
    Archive => "\u{1f4e6}"
    Image => "\u{1f5bc}"
    Audio => "\u{1f3b5}"
    Video => "\u{1f3ac}"
    Code => "\u{1f4dd}"
    Doc => "\u{1f4d1}"
    Symlink => "\u{1f517}"
    Other => "\u{1f4c4}"
  }
}

///|
/// 对齐字符串到指定宽度（左对齐，右侧填充空格）
pub fn pad_right(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    s
  } else {
    s + " ".repeat(width - len)
  }
}

///|
/// 对齐字符串到指定宽度（右对齐，左侧填充空格）
pub fn pad_left(s : String, width : Int) -> String {
  let len = s.length()
  if len >= width {
    s
  } else {
    " ".repeat(width - len) + s
  }
}

///|
/// 重复字符 n 次
pub fn repeat_char(c : Char, n : Int) -> String {
  if n <= 0 {
    ""
  } else {
    let buf = StringBuilder::new()
    let mut i = 0
    while i < n {
      buf.write_char(c)
      i = i + 1
    }
    buf.to_string()
  }
}

///|
/// 重复字符串 n 次
pub fn repeat_str(s : String, n : Int) -> String {
  if n <= 0 {
    ""
  } else {
    s.repeat(n)
  }
}

// ============================================================
// 字符工具
// ============================================================

///|
/// 字符转小写
pub fn char_to_lower(c : Char) -> Char {
  let code = c.to_int()
  if code >= 0x41 && code <= 0x5A {
    Int::unsafe_to_char(code + 32)
  } else {
    c
  }
}

///|
/// 字符转大写
pub fn char_to_upper(c : Char) -> Char {
  let code = c.to_int()
  if code >= 0x61 && code <= 0x7A {
    Int::unsafe_to_char(code - 32)
  } else {
    c
  }
}

///|
/// 是否数字
pub fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// 是否单词字符 [a-zA-Z0-9_]
pub fn is_word_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_'
}

///|
/// 是否空白字符
pub fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// 是否字母
pub fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
/// 是否字母或数字
pub fn is_alnum(c : Char) -> Bool {
  is_alpha(c) || is_digit(c)
}

// ============================================================
// 字符串工具
// ============================================================

///|
/// 将字符串按行分割
pub fn split_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  let buf = StringBuilder::new()
  for c in text.iter() {
    if c == '\n' {
      lines.push(buf.to_string())
      buf.reset()
    } else if c != '\r' {
      buf.write_char(c)
    }
  }
  let remaining = buf.to_string()
  if remaining.length() > 0 || text.length() > 0 {
    lines.push(remaining)
  }
  lines
}

///|
/// 统计行数、单词数、字符数
pub struct WcResult {
  lines : Int
  words : Int
  chars : Int
  bytes : Int
  max_line_length : Int
}

///|
/// 统计文本的行/单词/字符数
pub fn count_text(text : String) -> WcResult {
  let mut lines = 0
  let mut words = 0
  let mut chars = 0
  let mut bytes = 0
  let mut max_line = 0
  let mut current_line_len = 0
  let mut in_word = false
  for c in text.iter() {
    chars = chars + 1
    bytes = bytes + utf8_byte_len(c)
    if c == '\n' {
      lines = lines + 1
      if current_line_len > max_line {
        max_line = current_line_len
      }
      current_line_len = 0
      in_word = false
    } else if c == '\r' {
      continue
    } else {
      current_line_len = current_line_len + 1
      if c == ' ' || c == '\t' {
        in_word = false
      } else if !in_word {
        words = words + 1
        in_word = true
      }
    }
  }
  if current_line_len > max_line {
    max_line = current_line_len
  }
  if chars > 0 {
    let last_char = text[text.length() - 1]
    // UInt16 for '\n' is 10
    if last_char != 10 {
      lines = lines + 1
    }
  }
  { lines, words, chars, bytes, max_line_length: max_line }
}

///|
/// UTF-8 编码长度
fn utf8_byte_len(c : Char) -> Int {
  let code = c.to_int()
  if code < 0x80 {
    1
  } else if code < 0x800 {
    2
  } else if code < 0x10000 {
    3
  } else {
    4
  }
}

///|
/// 格式化权限字符串（从数字模式）
pub fn format_permissions(mode : Int) -> String {
  let buf = StringBuilder::new()
  // 文件类型
  let filetype = mode & 0xF000
  match filetype {
    0x4000 => buf.write_char('d')
    0xA000 => buf.write_char('l')
    _ => buf.write_char('-')
  }
  // 所有者权限
  buf.write_char(if (mode & 0x100) != 0 { 'r' } else { '-' })
  buf.write_char(if (mode & 0x080) != 0 { 'w' } else { '-' })
  buf.write_char(if (mode & 0x040) != 0 { 'x' } else { '-' })
  // 组权限
  buf.write_char(if (mode & 0x020) != 0 { 'r' } else { '-' })
  buf.write_char(if (mode & 0x010) != 0 { 'w' } else { '-' })
  buf.write_char(if (mode & 0x008) != 0 { 'x' } else { '-' })
  // 其他权限
  buf.write_char(if (mode & 0x004) != 0 { 'r' } else { '-' })
  buf.write_char(if (mode & 0x002) != 0 { 'w' } else { '-' })
  buf.write_char(if (mode & 0x001) != 0 { 'x' } else { '-' })
  buf.to_string()
}

///|
/// 格式化时间戳为可读时间（简化版）
pub fn format_timestamp(secs : Int64) -> String {
  // 将 Unix 时间戳转为 YYYY-MM-DD HH:MM:SS
  let total = secs.to_int()
  let days = total / 86400
  let secs_in_day = total % 86400
  let hours = secs_in_day / 3600
  let minutes = secs_in_day % 3600 / 60
  let seconds = secs_in_day % 60
  // 计算日期（从 1970-01-01 开始）
  let (year, month, day) = days_to_date(days)
  let buf = StringBuilder::new()
  buf.write_string(year.to_string())
  buf.write_char('-')
  if month < 10 {
    buf.write_char('0')
  }
  buf.write_string(month.to_string())
  buf.write_char('-')
  if day < 10 {
    buf.write_char('0')
  }
  buf.write_string(day.to_string())
  buf.write_char(' ')
  if hours < 10 {
    buf.write_char('0')
  }
  buf.write_string(hours.to_string())
  buf.write_char(':')
  if minutes < 10 {
    buf.write_char('0')
  }
  buf.write_string(minutes.to_string())
  buf.write_char(':')
  if seconds < 10 {
    buf.write_char('0')
  }
  buf.write_string(seconds.to_string())
  buf.to_string()
}

///|
/// 将天数转为年月日（从 1970-01-01）
fn days_to_date(days : Int) -> (Int, Int, Int) {
  let mut year = 1970
  let mut remaining = days
  while true {
    let days_in_year = if is_leap_year(year) { 366 } else { 365 }
    if remaining < days_in_year {
      break
    }
    remaining = remaining - days_in_year
    year = year + 1
  }
  let month_days = [
    31,
    if is_leap_year(year) {
      29
    } else {
      28
    },
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ]
  let mut month = 1
  while month <= 12 {
    if remaining < month_days[month - 1] {
      break
    }
    remaining = remaining - month_days[month - 1]
    month = month + 1
  }
  (year, month, remaining + 1)
}

///|
/// 是否闰年
fn is_leap_year(year : Int) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
/// 版本号
pub let moonsh_version : String = "0.2.0"

///|
/// moonsh 的完整描述
pub let moonsh_description : String = "MoonBit 工作区健康诊断与跨平台文本处理工具"

///|
/// 支持的命令列表
pub fn supported_commands() -> Array[String] {
  [
    "ls", "cat", "find", "grep", "wc", "head", "tail", "stat", "sort", "uniq", "cut",
    "tr", "diff", "md", "doctor",
  ]
}

///|
/// 安全解析字符串为整数（失败返回默认值）
pub fn parse_int_safe(s : String, default : Int) -> Int {
  @string.parse_int(s) catch {
    _ => default
  }
}

///|
/// 安全获取 flag 值
pub fn get_flag(flags : Map[String, Bool], name : String) -> Bool {
  match flags.get(name) {
    Some(v) => v
    None => false
  }
}

///|
/// 安全获取 option 值
pub fn get_option(values : Map[String, Array[String]], name : String) -> String {
  match values.get(name) {
    Some(arr) => if arr.is_empty() { "" } else { arr[0] }
    None => ""
  }
}

///|
/// 安全获取 positional 值
pub fn get_positional(
  values : Map[String, Array[String]],
  name : String,
  default : String,
) -> String {
  match values.get(name) {
    Some(arr) => if arr.is_empty() { default } else { arr[0] }
    None => default
  }
}

///|
/// 安全获取 positional 值列表
pub fn get_positional_list(
  values : Map[String, Array[String]],
  name : String,
) -> Array[String] {
  match values.get(name) {
    Some(arr) => arr
    None => []
  }
}
