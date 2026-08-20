// ls.mbt — ls 命令实现
// 列出目录内容，支持长格式、树形、颜色、隐藏文件

///|
/// ls 命令的运行入口
pub async fn run_ls(matches : @argparse.Matches) -> Unit {
  let show_all = get_flag(matches.flags, "all")
  let long_format = get_flag(matches.flags, "long")
  let tree_mode = get_flag(matches.flags, "tree")
  let use_color = get_flag(matches.flags, "color")
  let path = get_positional(matches.values, "path", ".")
  try {
    let kind = @fs.kind(path)
    match kind {
      Directory =>
        if tree_mode {
          ls_tree(path, show_all, use_color)
        } else if long_format {
          ls_long(path, show_all, use_color)
        } else {
          ls_short(path, show_all, use_color)
        }
      _ => {
        // 单个文件，直接显示
        let ft = detect_file_type(path)
        let display = if use_color {
          colorize(path, file_type_color(ft))
        } else {
          path
        }
        @stdio.stdout.write("\{display}\n")
      }
    }
  } catch {
    _ =>
      @stdio.stdout.write(
        "ls: cannot access '\{path}': No such file or directory\n",
      )
  }
}

///|
/// 短格式：列名横排显示
async fn ls_short(path : String, show_all : Bool, use_color : Bool) -> Unit {
  let entries = @fs.readdir(path, include_hidden=show_all, sort=true)
  if entries.is_empty() {
    return
  }
  let buf = StringBuilder::new()
  for name in entries {
    let ft = detect_file_type(name)
    let display = if use_color {
      let icon = file_type_icon(ft)
      "\{icon} \{colorize(name, file_type_color(ft))}"
    } else {
      name
    }
    buf.write_string(display)
    buf.write_string("  ")
  }
  buf.write_char('\n')
  @stdio.stdout.write(buf.to_string())
}

///|
/// 长格式：权限 大小 日期 文件名
async fn ls_long(path : String, show_all : Bool, use_color : Bool) -> Unit {
  let entries = @fs.readdir(path, include_hidden=show_all, sort=true)
  if entries.is_empty() {
    return
  }
  let buf = StringBuilder::new()
  // 收集文件信息
  for name in entries {
    let full_path = "\{path}/\{name}"
    let ft = detect_file_type(name)
    let size_str = try {
      let file = @fs.open(full_path, mode=ReadOnly)
      let size = file.size()
      file.close()
      format_size_int(size.to_int())
    } catch {
      _ => "-"
    }
    let mtime = try {
      let (secs, _) = @fs.mtime(full_path)
      format_timestamp(secs)
    } catch {
      _ => "-"
    }
    let perm = try {
      let kind = @fs.kind(full_path)
      match kind {
        Directory => 0x4000 | 0o755
        SymLink => 0xA000 | 0o777
        _ => 0o644
      }
    } catch {
      _ => 0
    }
    let perm_str = format_permissions(perm)
    let display_name = if use_color {
      colorize(name, file_type_color(ft))
    } else {
      name
    }
    buf.write_string(
      "\{perm_str} \{pad_left(size_str, 10)} \{mtime} \{display_name}\n",
    )
  }
  @stdio.stdout.write(buf.to_string())
}

///|
/// 树形显示
async fn ls_tree(path : String, show_all : Bool, use_color : Bool) -> Unit {
  let buf = StringBuilder::new()
  buf.write_string(path)
  buf.write_char('\n')
  ls_tree_recursive(path, "", show_all, use_color, buf, 0)
  @stdio.stdout.write(buf.to_string())
}

///|
/// 递归树形显示
async fn ls_tree_recursive(
  path : String,
  prefix : String,
  show_all : Bool,
  use_color : Bool,
  buf : StringBuilder,
  depth : Int,
) -> Unit {
  if depth > 10 {
    return
  }
  let entries = @fs.readdir(path, include_hidden=show_all, sort=true) catch {
    _ => return
  }
  let total = entries.length()
  let mut idx = 0
  for name in entries {
    idx = idx + 1
    let is_last = idx == total
    let full_path = "\{path}/\{name}"
    let ft = detect_file_type(name)
    let display_name = if use_color {
      colorize(name, file_type_color(ft))
    } else {
      name
    }
    // 绘制连接线
    let connector = if is_last { "└── " } else { "├── " }
    buf.write_string(prefix)
    buf.write_string(connector)
    buf.write_string(display_name)
    buf.write_char('\n')
    // 递归子目录
    let is_dir = try (@fs.kind(full_path) is Directory) catch {
      _ => false
    }
    if is_dir {
      let new_prefix = prefix + (if is_last { "    " } else { "│   " })
      ls_tree_recursive(
        full_path,
        new_prefix,
        show_all,
        use_color,
        buf,
        depth + 1,
      )
    }
  }
}
