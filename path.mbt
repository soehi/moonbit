// path.mbt — 路径处理工具模块
// 提供跨平台路径解析、拼接、规范化等功能

///|
/// 路径分隔符（Unix 风格）
pub let path_sep : String = "/"

///|
/// Windows 路径分隔符
pub let path_sep_win : String = "\\"

///|
/// 路径类型枚举
pub enum PathType {
  Absolute
  Relative
  HomeRelative
  DotRelative
  Empty
}

///|
/// 检测路径类型
pub fn path_type(path : String) -> PathType {
  if path.length() == 0 {
    return Empty
  }
  // Unix 绝对路径
  if path[0] == '/' {
    return Absolute
  }
  // Windows 绝对路径 (C:\ 或 C:/)
  if path.length() >= 3 {
    let c0 = path[0]
    let c1 = path[1]
    let c2 = path[2]
    if ((c0 >= 'A' && c0 <= 'Z') || (c0 >= 'a' && c0 <= 'z')) &&
      c1 == ':' &&
      (c2 == '/' || c2 == '\\') {
      return Absolute
    }
  }
  // Home 相对路径 (~)
  if path[0] == '~' {
    return HomeRelative
  }
  // Dot 相对路径 (./ 或 ../)
  if path[0] == '.' {
    if path.length() == 1 {
      return DotRelative
    }
    let c1 = path[1]
    if c1 == '/' || c1 == '\\' {
      return DotRelative
    }
    if c1 == '.' {
      if path.length() == 2 {
        return DotRelative
      }
      let c2 = path[2]
      if c2 == '/' || c2 == '\\' {
        return DotRelative
      }
    }
  }
  Relative
}

///|
/// 判断路径是否为绝对路径
pub fn is_absolute_path(path : String) -> Bool {
  match path_type(path) {
    Absolute => true
    _ => false
  }
}

///|
/// 判断路径是否为相对路径
pub fn is_relative_path(path : String) -> Bool {
  match path_type(path) {
    Absolute => false
    Empty => false
    _ => true
  }
}

///|
/// 规范化路径分隔符（将所有 \ 转为 /）
pub fn normalize_separators(path : String) -> String {
  let buf = StringBuilder::new()
  for c in path.iter() {
    if c == '\\' {
      buf.write_char('/')
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// 拼接路径
pub fn join_paths(base : String, child : String) -> String {
  if child.length() == 0 {
    return base
  }
  if base.length() == 0 {
    return child
  }
  let base_norm = normalize_separators(base)
  let child_norm = normalize_separators(child)
  // 如果 child 是绝对路径，直接返回 child
  if is_absolute_path(child_norm) {
    return child_norm
  }
  let base_last = base_norm[base_norm.length() - 1]
  let child_first = child_norm[0]
  if base_last == '/' {
    if child_first == '/' {
      base_norm + child_norm.substring(start=1)
    } else {
      base_norm + child_norm
    }
  } else if child_first == '/' {
    base_norm + child_norm
  } else {
    base_norm + "/" + child_norm
  }
}

///|
/// 规范化路径（消除 . 和 .. ）
pub fn normalize_path(path : String) -> String {
  let normalized = normalize_separators(path)
  let is_abs = is_absolute_path(normalized)
  let parts : Array[String] = []
  let segments = split_path_segments(normalized)
  for seg in segments {
    if seg == "." {
      // 当前目录，跳过
      continue
    }
    if seg == ".." {
      // 上级目录，弹出最后一个（如果存在且不是 ..）
      if not(parts.is_empty()) {
        let last = parts[parts.length() - 1]
        if last != ".." {
          ignore(parts.pop())
        } else {
          parts.push(seg)
        }
      } else {
        parts.push(seg)
      }
    } else if seg.length() > 0 {
      parts.push(seg)
    }
  }
  // 构建结果
  let buf = StringBuilder::new()
  if is_abs {
    buf.write_char('/')
  }
  let mut first = true
  for part in parts {
    if not(first) {
      buf.write_char('/')
    }
    buf.write_string(part)
    first = false
  }
  let result = buf.to_string()
  if result.length() == 0 {
    if is_abs {
      "/"
    } else {
      "."
    }
  } else {
    result
  }
}

///|
/// 将路径按分隔符分割成段
pub fn split_path_segments(path : String) -> Array[String] {
  let result : Array[String] = []
  let buf = StringBuilder::new()
  for c in path.iter() {
    if c == '/' || c == '\\' {
      let seg = buf.to_string()
      if seg.length() > 0 {
        result.push(seg)
      }
      buf.reset()
    } else {
      buf.write_char(c)
    }
  }
  let last = buf.to_string()
  if last.length() > 0 {
    result.push(last)
  }
  result
}

///|
/// 获取路径的父目录
pub fn parent_dir(path : String) -> String {
  let normalized = normalize_separators(path)
  match normalized.rev_find("/") {
    Some(pos) =>
      if pos == 0 {
        // 根目录
        "/"
      } else {
        normalized.substring(start=0, end=pos)
      }
    None => "."
  }
}

///|
/// 获取路径最后一段（文件名或目录名）
pub fn path_filename(path : String) -> String {
  let normalized = normalize_separators(path)
  match normalized.rev_find("/") {
    Some(pos) =>
      if pos == normalized.length() - 1 {
        // 以 / 结尾，去掉再找
        let trimmed = normalized.substring(start=0, end=normalized.length() - 1)
        match trimmed.rev_find("/") {
          Some(p) => trimmed.substring(start=p + 1)
          None => trimmed
        }
      } else {
        normalized.substring(start=pos + 1)
      }
    None => normalized
  }
}

///|
/// 获取路径的扩展名（含点号，如 ".txt"）
pub fn path_extension(path : String) -> String {
  let fname = path_filename(path)
  // 处理以 . 开头的文件名（如 .gitignore）
  match fname.rev_find(".") {
    Some(pos) =>
      if pos == 0 {
        // 隐藏文件，无扩展名
        ""
      } else {
        fname.substring(start=pos)
      }
    None => ""
  }
}

///|
/// 去除路径的扩展名
pub fn remove_extension(path : String) -> String {
  let ext = path_extension(path)
  if ext.length() == 0 {
    path
  } else {
    let end_pos = path.length() - ext.length()
    path.substring(start=0, end=end_pos)
  }
}

///|
/// 替换路径的扩展名
pub fn replace_extension(path : String, new_ext : String) -> String {
  let base = remove_extension(path)
  let prefix = if new_ext.length() > 0 && new_ext[0] != '.' { "." } else { "" }
  base + prefix + new_ext
}

///|
/// 获取路径的所有父级目录链
/// 例如 /a/b/c -> ["/a/b/c", "/a/b", "/a", "/"]
pub fn path_ancestors(path : String) -> Array[String] {
  let normalized = normalize_path(path)
  let result : Array[String] = [normalized]
  let mut current = normalized
  while current != "/" && current != "." {
    let parent = parent_dir(current)
    if parent == current {
      break
    }
    result.push(parent)
    current = parent
  }
  result
}

///|
/// 计算从 base 到 target 的相对路径
pub fn relative_path(base : String, target : String) -> String {
  let base_norm = normalize_path(normalize_separators(base))
  let target_norm = normalize_path(normalize_separators(target))
  let base_segs = split_path_segments(base_norm)
  let target_segs = split_path_segments(target_norm)
  // 找公共前缀
  let mut common = 0
  while common < base_segs.length() &&
        common < target_segs.length() &&
        base_segs[common] == target_segs[common] {
    common = common + 1
  }
  // 构建 ../ 部分
  let up_count = base_segs.length() - common
  let result : Array[String] = []
  let mut i = 0
  while i < up_count {
    result.push("..")
    i = i + 1
  }
  // 构建 target 剩余部分
  let mut j = common
  while j < target_segs.length() {
    result.push(target_segs[j])
    j = j + 1
  }
  if result.is_empty() {
    "."
  } else {
    let buf = StringBuilder::new()
    let mut first = true
    for seg in result {
      if not(first) {
        buf.write_char('/')
      }
      buf.write_string(seg)
      first = false
    }
    buf.to_string()
  }
}

///|
/// 判断路径是否以指定后缀结尾
pub fn path_has_suffix(path : String, suffix : String) -> Bool {
  path.has_suffix(suffix)
}

///|
/// 判断路径是否以指定前缀开头
pub fn path_has_prefix(path : String, prefix : String) -> Bool {
  path.has_prefix(prefix)
}

///|
/// 清理路径尾部的分隔符
pub fn strip_trailing_sep(path : String) -> String {
  let mut result = path
  while result.length() > 1 {
    let last = result[result.length() - 1]
    if last == '/' || last == '\\' {
      result = result.substring(start=0, end=result.length() - 1)
    } else {
      break
    }
  }
  result
}

///|
/// 路径深度（从根到叶的段数）
pub fn path_depth(path : String) -> Int {
  let segs = split_path_segments(normalize_path(path))
  let mut depth = 0
  for seg in segs {
    if seg != "" && seg != "." {
      depth = depth + 1
    }
  }
  depth
}

///|
/// 路径拼接（多段）
pub fn join_path_multi(paths : Array[String]) -> String {
  if paths.is_empty() {
    return ""
  }
  let mut result = paths[0]
  let mut i = 1
  while i < paths.length() {
    result = join_paths(result, paths[i])
    i = i + 1
  }
  result
}

///|
/// 检查路径是否在指定目录内
pub fn is_path_inside(path : String, dir : String) -> Bool {
  let path_norm = normalize_path(path)
  let dir_norm = normalize_path(dir)
  let dir_stripped = strip_trailing_sep(dir_norm)
  path_norm == dir_stripped || path_norm.has_prefix(dir_stripped + "/")
}
