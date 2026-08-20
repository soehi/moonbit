// cat.mbt — cat 命令实现
// 查看文件内容，支持行号和语法高亮

///|
/// cat 命令的运行入口
pub async fn run_cat(matches : @argparse.Matches) -> Unit {
  let show_number = get_flag(matches.flags, "number")
  let use_color = get_flag(matches.flags, "color")
  let files = get_positional_list(matches.values, "file")
  if files.is_empty() {
    // 从 stdin 读取
    let data = @stdio.stdin.read_all()
    let text = data.text()
    output_text(text, show_number, use_color, "")
  } else {
    for file in files {
      if file == "-" {
        let data = @stdio.stdin.read_all()
        let text = data.text()
        output_text(text, show_number, use_color, "")
      } else {
        try {
          let data = @fs.read_file(file)
          let text = data.text()
          let ext = get_extension(file)
          output_text(text, show_number, use_color, ext)
        } catch {
          _ => @stdio.stdout.write("cat: \{file}: No such file or directory\n")
        }
      }
    }
  }
}

///|
/// 输出文本内容
async fn output_text(
  text : String,
  show_number : Bool,
  use_color : Bool,
  _ext : String,
) -> Unit {
  let lines = split_lines(text)
  let buf = StringBuilder::new()
  let mut line_num = 1
  for line in lines {
    if show_number {
      let num_str = pad_left(line_num.to_string(), 6)
      if use_color {
        buf.write_string(colorize(num_str, BrightBlack))
      } else {
        buf.write_string(num_str)
      }
      buf.write_char(' ')
      buf.write_char('\t')
    }
    buf.write_string(line)
    buf.write_char('\n')
    line_num = line_num + 1
  }
  @stdio.stdout.write(buf.to_string())
}
