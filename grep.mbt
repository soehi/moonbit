// grep.mbt — grep 命令实现
// 文本搜索，支持正则表达式、行号、上下文、反向匹配

///|
/// grep 命令的运行入口
pub async fn run_grep(matches : @argparse.Matches) -> Unit {
  let ignore_case = get_flag(matches.flags, "ignore_case")
  let show_line_number = get_flag(matches.flags, "line_number")
  let invert = get_flag(matches.flags, "invert")
  let context_count = {
    let v = get_option(matches.values, "context")
    if v == "" {
      0
    } else {
      parse_int_safe(v, 0)
    }
  }
  let pattern = get_positional(matches.values, "pattern", "")
  let files = get_positional_list(matches.values, "file")
  let flags = { ignore_case, multiline: false }
  if files.is_empty() {
    // 从 stdin 读取
    let data = @stdio.stdin.read_all()
    let text = data.text()
    grep_in_text(
      text, pattern, flags, show_line_number, invert, context_count, "",
    )
  } else {
    for file in files {
      if file == "-" {
        let data = @stdio.stdin.read_all()
        let text = data.text()
        grep_in_text(
          text, pattern, flags, show_line_number, invert, context_count, "",
        )
      } else {
        try {
          let data = @fs.read_file(file)
          let text = data.text()
          grep_in_text(
            text, pattern, flags, show_line_number, invert, context_count, file,
          )
        } catch {
          _ => @stdio.stdout.write("grep: \{file}: No such file or directory\n")
        }
      }
    }
  }
}

///|
/// 在文本中搜索
async fn grep_in_text(
  text : String,
  pattern : String,
  flags : RegexFlags,
  show_line_number : Bool,
  invert : Bool,
  context_count : Int,
  filename : String,
) -> Unit {
  let lines = split_lines(text)
  let buf = StringBuilder::new()
  let total = lines.length()
  let mut i = 0
  while i < total {
    let line = lines[i]
    let matched = if pattern == "" {
      true
    } else {
      regex_find_flags(pattern, line, flags).length() > 0
    }
    let should_show = if invert { !matched } else { matched }
    if should_show {
      // 显示文件名前缀
      if filename != "" {
        buf.write_string(colorize("\{filename}:", Green))
      }
      // 行号
      if show_line_number {
        let num = colorize("\{i + 1}:", BrightBlack)
        buf.write_string(num)
      }
      // 匹配行内容
      buf.write_string(line)
      buf.write_char('\n')
      // 上下文
      if context_count > 0 {
        let mut j = 1
        while j <= context_count && i + j < total {
          let ctx_line = lines[i + j]
          if filename != "" {
            buf.write_string(colorize("\{filename}-", BrightBlack))
          }
          if show_line_number {
            buf.write_string(colorize("\{i + j + 1}-", BrightBlack))
          }
          buf.write_string(ctx_line)
          buf.write_char('\n')
          j = j + 1
        }
      }
    }
    i = i + 1
  }
  @stdio.stdout.write(buf.to_string())
}
