// wc.mbt — wc 命令实现
// 统计行数、单词数、字符数

///|
/// wc 命令的运行入口
pub async fn run_wc(matches : @argparse.Matches) -> Unit {
  let only_lines = get_flag(matches.flags, "lines")
  let only_words = get_flag(matches.flags, "words")
  let only_chars = get_flag(matches.flags, "chars")
  let files = get_positional_list(matches.values, "file")
  if files.is_empty() {
    let data = @stdio.stdin.read_all()
    let text = data.text()
    let result = count_text(text)
    output_wc_result(result, only_lines, only_words, only_chars, "")
  } else {
    for file in files {
      if file == "-" {
        let data = @stdio.stdin.read_all()
        let text = data.text()
        let result = count_text(text)
        output_wc_result(result, only_lines, only_words, only_chars, "")
      } else {
        try {
          let data = @fs.read_file(file)
          let text = data.text()
          let result = count_text(text)
          output_wc_result(result, only_lines, only_words, only_chars, file)
        } catch {
          _ => @stdio.stdout.write("wc: \{file}: No such file or directory\n")
        }
      }
    }
  }
}

///|
/// 输出 wc 统计结果
async fn output_wc_result(
  result : WcResult,
  only_lines : Bool,
  only_words : Bool,
  only_chars : Bool,
  filename : String,
) -> Unit {
  let buf = StringBuilder::new()
  if only_lines {
    buf.write_string(pad_left(result.lines.to_string(), 8))
  } else if only_words {
    buf.write_string(pad_left(result.words.to_string(), 8))
  } else if only_chars {
    buf.write_string(pad_left(result.chars.to_string(), 8))
  } else {
    buf.write_string(pad_left(result.lines.to_string(), 8))
    buf.write_string(pad_left(result.words.to_string(), 8))
    buf.write_string(pad_left(result.chars.to_string(), 8))
    buf.write_string(pad_left(result.max_line_length.to_string(), 8))
  }
  if filename != "" {
    buf.write_char(' ')
    buf.write_string(filename)
  }
  buf.write_char('\n')
  @stdio.stdout.write(buf.to_string())
}
