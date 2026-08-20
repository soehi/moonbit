// head_tail.mbt — head 和 tail 命令实现
// 显示文件开头或末尾若干行

///|
/// head 命令的运行入口
pub async fn run_head(matches : @argparse.Matches) -> Unit {
  let n = {
    let v = get_option(matches.values, "lines")
    if v == "" {
      10
    } else {
      parse_int_safe(v, 10)
    }
  }
  let files = get_positional_list(matches.values, "file")
  if files.is_empty() {
    let data = @stdio.stdin.read_all()
    let text = data.text()
    let lines = split_lines(text)
    let limit = if n < lines.length() { n } else { lines.length() }
    let buf = StringBuilder::new()
    for i in 0..<limit {
      buf.write_string(lines[i])
      buf.write_char('\n')
    }
    @stdio.stdout.write(buf.to_string())
  } else {
    for file in files {
      if file == "-" {
        let data = @stdio.stdin.read_all()
        let text = data.text()
        let lines = split_lines(text)
        let limit = if n < lines.length() { n } else { lines.length() }
        let buf = StringBuilder::new()
        for i in 0..<limit {
          buf.write_string(lines[i])
          buf.write_char('\n')
        }
        @stdio.stdout.write(buf.to_string())
      } else {
        try {
          let data = @fs.read_file(file)
          let text = data.text()
          let lines = split_lines(text)
          let limit = if n < lines.length() { n } else { lines.length() }
          let buf = StringBuilder::new()
          for i in 0..<limit {
            buf.write_string(lines[i])
            buf.write_char('\n')
          }
          @stdio.stdout.write(buf.to_string())
        } catch {
          _ =>
            @stdio.stdout.write(
              "head: cannot open '\{file}' for reading: No such file or directory\n",
            )
        }
      }
    }
  }
}

///|
/// tail 命令的运行入口
pub async fn run_tail(matches : @argparse.Matches) -> Unit {
  let n = {
    let v = get_option(matches.values, "lines")
    if v == "" {
      10
    } else {
      parse_int_safe(v, 10)
    }
  }
  let files = get_positional_list(matches.values, "file")
  if files.is_empty() {
    let data = @stdio.stdin.read_all()
    let text = data.text()
    let lines = split_lines(text)
    let start = if lines.length() > n { lines.length() - n } else { 0 }
    let buf = StringBuilder::new()
    for i in start..<lines.length() {
      buf.write_string(lines[i])
      buf.write_char('\n')
    }
    @stdio.stdout.write(buf.to_string())
  } else {
    for file in files {
      if file == "-" {
        let data = @stdio.stdin.read_all()
        let text = data.text()
        let lines = split_lines(text)
        let start = if lines.length() > n { lines.length() - n } else { 0 }
        let buf = StringBuilder::new()
        for i in start..<lines.length() {
          buf.write_string(lines[i])
          buf.write_char('\n')
        }
        @stdio.stdout.write(buf.to_string())
      } else {
        try {
          let data = @fs.read_file(file)
          let text = data.text()
          let lines = split_lines(text)
          let start = if lines.length() > n { lines.length() - n } else { 0 }
          let buf = StringBuilder::new()
          for i in start..<lines.length() {
            buf.write_string(lines[i])
            buf.write_char('\n')
          }
          @stdio.stdout.write(buf.to_string())
        } catch {
          _ =>
            @stdio.stdout.write(
              "tail: cannot open '\{file}' for reading: No such file or directory\n",
            )
        }
      }
    }
  }
}
