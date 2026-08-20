// glob.mbt — Glob 模式匹配引擎
// 支持 * / ? / [...] / ** 等通配符

///|
/// Glob 匹配 — 支持 * / ? / [...] / **
/// pattern: "*.txt", "src/**/*.moonbit", "[abc]*.rs"
pub fn glob_match(pattern : String, text : String) -> Bool {
  let pchars = pattern.to_array()
  let tchars = text.to_array()
  glob_match_impl(pchars, 0, tchars, 0)
}

///|
/// Glob 匹配核心实现（递归回溯）
fn glob_match_impl(
  pattern : Array[Char],
  pi : Int,
  text : Array[Char],
  ti : Int,
) -> Bool {
  if pi == pattern.length() {
    return ti == text.length()
  }
  let pc = pattern[pi]
  match pc {
    '*' => {
      // ** 匹配跨目录
      if pi + 1 < pattern.length() && pattern[pi + 1] == '*' {
        if pi + 2 < pattern.length() && pattern[pi + 2] == '/' {
          // **/ 匹配任意深度目录
          return glob_starstar(pattern, pi + 3, text, ti)
        } else if pi + 2 == pattern.length() {
          // pattern 以 ** 结尾，匹配一切
          return true
        }
      }
      // 普通 * 匹配非 / 字符
      glob_star(pattern, pi + 1, text, ti)
    }
    '?' =>
      if ti < text.length() && text[ti] != '/' {
        glob_match_impl(pattern, pi + 1, text, ti + 1)
      } else {
        false
      }
    '[' => glob_bracket(pattern, pi, text, ti)
    _ =>
      if ti < text.length() && text[ti] == pc {
        glob_match_impl(pattern, pi + 1, text, ti + 1)
      } else {
        false
      }
  }
}

///|
/// 处理 * 通配符：匹配零或多个非 / 字符
fn glob_star(
  pattern : Array[Char],
  pi : Int,
  text : Array[Char],
  ti : Int,
) -> Bool {
  // 尝试跳过 0 个字符
  if glob_match_impl(pattern, pi, text, ti) {
    return true
  }
  // 尝试匹配一个字符然后递归
  if ti < text.length() && text[ti] != '/' {
    glob_star(pattern, pi, text, ti + 1)
  } else {
    false
  }
}

///|
/// 处理 ** 通配符：匹配任意路径段
fn glob_starstar(
  pattern : Array[Char],
  pi : Int,
  text : Array[Char],
  ti : Int,
) -> Bool {
  let mut idx = ti
  while idx <= text.length() {
    if glob_match_impl(pattern, pi, text, idx) {
      return true
    }
    idx = idx + 1
  }
  false
}

///|
/// 处理 [...] 字符类
fn glob_bracket(
  pattern : Array[Char],
  pi : Int,
  text : Array[Char],
  ti : Int,
) -> Bool {
  if ti >= text.length() {
    return false
  }
  let tc = text[ti]
  let mut idx = pi + 1
  let mut negate = false
  if idx < pattern.length() && (pattern[idx] == '!' || pattern[idx] == '^') {
    negate = true
    idx = idx + 1
  }
  let mut matched = false
  while idx < pattern.length() && pattern[idx] != ']' {
    if idx + 2 < pattern.length() &&
      pattern[idx + 1] == '-' &&
      pattern[idx + 2] != ']' {
      // 范围 [a-z]
      let lo = pattern[idx]
      let hi = pattern[idx + 2]
      if tc >= lo && tc <= hi {
        matched = true
      }
      idx = idx + 3
    } else {
      if pattern[idx] == tc {
        matched = true
      }
      idx = idx + 1
    }
  }
  // 找到 ] 的位置
  if idx >= pattern.length() {
    return false // 没有闭合 ]
  }
  let after_bracket = idx + 1
  let result = if negate { !matched && tc != '/' } else { matched }
  if result {
    glob_match_impl(pattern, after_bracket, text, ti + 1)
  } else {
    false
  }
}
