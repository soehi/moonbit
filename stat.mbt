// stat.mbt — stat 命令实现
// 显示文件详细信息

///|
/// stat 命令的运行入口
pub async fn run_stat(matches : @argparse.Matches) -> Unit {
  let file = get_positional(matches.values, "file", "")
  if file == "" {
    @stdio.stdout.write("stat: missing file operand\n")
    return
  }
  try {
    let kind = @fs.kind(file)
    let ft = detect_file_type(file)
    let size = try {
      let f = @fs.open(file, mode=ReadOnly)
      let s = f.size()
      f.close()
      s
    } catch {
      _ => 0L
    }
    let (mtime, _) = @fs.mtime(file) catch { _ => (0L, 0) }
    let (atime, _) = @fs.atime(file) catch { _ => (0L, 0) }
    let can_read = @fs.can_read(file) catch { _ => false }
    let can_write = @fs.can_write(file) catch { _ => false }
    let can_execute = @fs.can_execute(file) catch { _ => false }
    let buf = StringBuilder::new()
    buf.write_string("  File: ")
    buf.write_string(colorize(file, file_type_color(ft)))
    buf.write_char('\n')
    buf.write_string("  Size: ")
    buf.write_string(format_size(size))
    buf.write_string("\t\t")
    buf.write_string("Type: ")
    buf.write_string(file_kind_str(kind))
    buf.write_char('\n')
    buf.write_string("Access: ")
    buf.write_string(format_timestamp(atime))
    buf.write_char('\n')
    buf.write_string("Modify: ")
    buf.write_string(format_timestamp(mtime))
    buf.write_char('\n')
    buf.write_string("  Perms: ")
    let perm_str = match kind {
      Directory => format_permissions(0x4000 | 0o755)
      SymLink => format_permissions(0xA000 | 0o777)
      _ => format_permissions(0o644)
    }
    buf.write_string(perm_str)
    buf.write_string("  (")
    if can_read {
      buf.write_char('r')
    } else {
      buf.write_char('-')
    }
    if can_write {
      buf.write_char('w')
    } else {
      buf.write_char('-')
    }
    if can_execute {
      buf.write_char('x')
    } else {
      buf.write_char('-')
    }
    buf.write_string(")\n")
    @stdio.stdout.write(buf.to_string())
  } catch {
    _ =>
      @stdio.stdout.write(
        "stat: cannot stat '\{file}': No such file or directory\n",
      )
  }
}

///|
/// 文件类型枚举转字符串
fn file_kind_str(kind : @fs.FileKind) -> String {
  match kind {
    Regular => "Regular File"
    Directory => "Directory"
    SymLink => "Symbolic Link"
    Socket => "Socket"
    Pipe => "Pipe"
    BlockDevice => "Block Device"
    CharDevice => "Character Device"
    Unknown => "Unknown"
  }
}
