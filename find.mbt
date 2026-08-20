// find.mbt — find 命令实现
// 搜索文件，支持 glob 模式匹配、文件类型过滤、深度控制

///|
/// find 命令的运行入口
pub async fn run_find(matches : @argparse.Matches) -> Unit {
  let include_hidden = get_flag(matches.flags, "hidden")
  let type_filter = get_flag(matches.flags, "type")
  let name_pattern = get_option(matches.values, "name")
  let max_depth = {
    let v = get_option(matches.values, "maxdepth")
    if v == "" {
      999
    } else {
      parse_int_safe(v, 999)
    }
  }
  let path = get_positional(matches.values, "path", ".")
  let pattern = {
    let p = get_positional(matches.values, "pattern", "")
    if p == "" {
      name_pattern
    } else {
      p
    }
  }
  let buf = StringBuilder::new()
  find_recursive(path, pattern, include_hidden, type_filter, max_depth, buf, 0)
  @stdio.stdout.write(buf.to_string())
}

///|
/// 递归搜索文件
async fn find_recursive(
  path : String,
  pattern : String,
  include_hidden : Bool,
  type_filter : Bool,
  max_depth : Int,
  buf : StringBuilder,
  depth : Int,
) -> Unit {
  if depth > max_depth {
    return
  }
  let entries = @fs.readdir(path, include_hidden~, sort=true) catch {
    _ => return
  }
  for name in entries {
    let full_path = "\{path}/\{name}"
    // 检查 glob 匹配
    let name_matches = if pattern == "" {
      true
    } else {
      glob_match(pattern, name)
    }
    let is_dir = try (@fs.kind(full_path) is Directory) catch {
      _ => false
    }
    if name_matches {
      if type_filter {
        // type_filter=true 表示只显示目录
        if is_dir {
          buf.write_string(full_path)
          buf.write_char('\n')
        }
      } else {
        buf.write_string(full_path)
        buf.write_char('\n')
      }
    }
    // 递归
    if is_dir {
      find_recursive(
        full_path,
        pattern,
        include_hidden,
        type_filter,
        max_depth,
        buf,
        depth + 1,
      )
    }
  }
}
