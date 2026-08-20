// regex.mbt — 简单正则引擎（子集）
// 支持: . * ? + ^ $ [a-z] [^a-z] | \d \w \s \b
// 用于 grep 命令的文本搜索

///|
/// 正则匹配标志
pub struct RegexFlags {
  ignore_case : Bool
  multiline : Bool
}

///|
/// 默认正则标志
pub fn RegexFlags::default() -> RegexFlags {
  { ignore_case: false, multiline: false }
}

///|
/// 编译后的正则
priv struct CompiledRegex {
  tokens : Array[RegexToken]
  anchored_start : Bool
  anchored_end : Bool
}

///|
/// 正则 token 类型
priv enum RegexToken {
  Literal(Char)
  AnyChar // .
  CharClass(Array[(Char, Char)], Bool) // ranges, negated
  Digit // \d
  NotDigit // \D
  Word // \w
  NotWord // \W
  Space // \s
  NotSpace // \S
  Star(Array[RegexToken]) // (pattern)*
  Plus(Array[RegexToken]) // (pattern)+
  Optional(Array[RegexToken]) // (pattern)?
  WordBoundary // \b
}

///|
/// 简单正则匹配 — 是否匹配
pub fn regex_match(pattern : String, text : String) -> Bool {
  regex_find(pattern, text).length() > 0
}

///|
/// 正则查找：返回所有匹配的起始位置
pub fn regex_find(pattern : String, text : String) -> Array[Int] {
  regex_find_flags(pattern, text, RegexFlags::default())
}

///|
/// 带标志的正则查找
pub fn regex_find_flags(
  pattern : String,
  text : String,
  flags : RegexFlags,
) -> Array[Int] {
  let result : Array[Int] = []
  let compiled = compile_regex(pattern, flags)
  let anchored_start = compiled.anchored_start
  let chars = text.to_array()
  let mut start = 0
  while start <= chars.length() {
    let match_len = regex_match_at(compiled, chars, start, flags)
    if match_len >= 0 {
      result.push(start)
      if match_len == 0 {
        start = start + 1
      } else {
        start = start + match_len
      }
    } else {
      if anchored_start {
        break
      }
      start = start + 1
    }
  }
  result
}

///|
/// 编译正则模式
fn compile_regex(pattern : String, _flags : RegexFlags) -> CompiledRegex {
  let tokens : Array[RegexToken] = []
  let chars = pattern.to_array()
  let mut i = 0
  let mut anchored_start = false
  let mut anchored_end = false
  // 检查 ^ 开头
  if chars.length() > 0 && chars[0] == '^' {
    anchored_start = true
    i = 1
  }
  while i < chars.length() {
    let c = chars[i]
    match c {
      '$' => {
        if i == chars.length() - 1 {
          anchored_end = true
        } else {
          tokens.push(RegexToken::Literal('$'))
        }
        i = i + 1
      }
      '.' =>
        if i + 1 < chars.length() {
          let q = chars[i + 1]
          if q == '*' {
            tokens.push(RegexToken::Star([RegexToken::AnyChar]))
            i = i + 2
          } else if q == '+' {
            tokens.push(RegexToken::Plus([RegexToken::AnyChar]))
            i = i + 2
          } else if q == '?' {
            tokens.push(RegexToken::Optional([RegexToken::AnyChar]))
            i = i + 2
          } else {
            tokens.push(RegexToken::AnyChar)
            i = i + 1
          }
        } else {
          tokens.push(RegexToken::AnyChar)
          i = i + 1
        }
      '\\' =>
        if i + 1 < chars.length() {
          let next = chars[i + 1]
          match next {
            'd' => tokens.push(RegexToken::Digit)
            'D' => tokens.push(RegexToken::NotDigit)
            'w' => tokens.push(RegexToken::Word)
            'W' => tokens.push(RegexToken::NotWord)
            's' => tokens.push(RegexToken::Space)
            'S' => tokens.push(RegexToken::NotSpace)
            'b' => tokens.push(RegexToken::WordBoundary)
            'n' => tokens.push(RegexToken::Literal('\n'))
            't' => tokens.push(RegexToken::Literal('\t'))
            'r' => tokens.push(RegexToken::Literal('\r'))
            _ => tokens.push(RegexToken::Literal(next))
          }
          i = i + 2
        } else {
          tokens.push(RegexToken::Literal('\\'))
          i = i + 1
        }
      '[' => {
        let (token, next_i) = parse_char_class(chars, i)
        tokens.push(token)
        i = next_i
      }
      '(' => {
        let (group_tokens, next_i) = parse_group(chars, i)
        if next_i < chars.length() {
          let q = chars[next_i]
          if q == '*' {
            tokens.push(RegexToken::Star(group_tokens))
            i = next_i + 1
          } else if q == '+' {
            tokens.push(RegexToken::Plus(group_tokens))
            i = next_i + 1
          } else if q == '?' {
            tokens.push(RegexToken::Optional(group_tokens))
            i = next_i + 1
          } else {
            for t in group_tokens {
              tokens.push(t)
            }
            i = next_i
          }
        } else {
          for t in group_tokens {
            tokens.push(t)
          }
          i = next_i
        }
      }
      _ =>
        if i + 1 < chars.length() {
          let q = chars[i + 1]
          if q == '*' {
            tokens.push(RegexToken::Star([RegexToken::Literal(c)]))
            i = i + 2
          } else if q == '+' {
            tokens.push(RegexToken::Plus([RegexToken::Literal(c)]))
            i = i + 2
          } else if q == '?' {
            tokens.push(RegexToken::Optional([RegexToken::Literal(c)]))
            i = i + 2
          } else {
            tokens.push(RegexToken::Literal(c))
            i = i + 1
          }
        } else {
          tokens.push(RegexToken::Literal(c))
          i = i + 1
        }
    }
  }
  { tokens, anchored_start, anchored_end }
}

///|
/// 解析字符类 [a-z] [^abc]
fn parse_char_class(chars : Array[Char], start : Int) -> (RegexToken, Int) {
  let ranges : Array[(Char, Char)] = []
  let mut negated = false
  let mut i = start + 1
  if i < chars.length() && (chars[i] == '^' || chars[i] == '!') {
    negated = true
    i = i + 1
  }
  while i < chars.length() && chars[i] != ']' {
    let c = chars[i]
    if i + 2 < chars.length() && chars[i + 1] == '-' && chars[i + 2] != ']' {
      ranges.push((c, chars[i + 2]))
      i = i + 3
    } else {
      ranges.push((c, c))
      i = i + 1
    }
  }
  if i < chars.length() {
    i = i + 1
  }
  (RegexToken::CharClass(ranges, negated), i)
}

///|
/// 解析分组 (...)
fn parse_group(chars : Array[Char], start : Int) -> (Array[RegexToken], Int) {
  let mut depth = 1
  let mut i = start + 1
  let group_start = i
  while i < chars.length() && depth > 0 {
    match chars[i] {
      '(' => depth = depth + 1
      ')' => depth = depth - 1
      _ => ()
    }
    if depth > 0 {
      i = i + 1
    }
  }
  let group_str = String::from_array(chars[group_start:i])
  let end_pos = if i < chars.length() { i + 1 } else { i }
  let inner = compile_regex(group_str, RegexFlags::default())
  (inner.tokens, end_pos)
}

///|
/// 在指定位置尝试匹配正则，返回匹配长度（-1 表示不匹配）
fn regex_match_at(
  compiled : CompiledRegex,
  text : Array[Char],
  start : Int,
  flags : RegexFlags,
) -> Int {
  let result = match_tokens(compiled.tokens, 0, text, start, flags)
  match result {
    Some(end) =>
      if compiled.anchored_end && end != text.length() {
        -1
      } else {
        end - start
      }
    None => -1
  }
}

///|
/// 递归匹配从 token_idx 开始的剩余 tokens，返回匹配结束位置
fn match_tokens(
  tokens : Array[RegexToken],
  token_idx : Int,
  text : Array[Char],
  pos : Int,
  flags : RegexFlags,
) -> Int? {
  if token_idx >= tokens.length() {
    return Some(pos)
  }
  let token = tokens[token_idx]
  match token {
    Literal(c) => {
      if pos >= text.length() {
        return None
      }
      let tc = text[pos]
      let matched = if flags.ignore_case {
        char_to_lower(tc) == char_to_lower(c)
      } else {
        tc == c
      }
      if !matched {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    AnyChar => {
      if pos >= text.length() {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    CharClass(ranges, negated) => {
      if pos >= text.length() {
        return None
      }
      let tc = text[pos]
      let mut found = false
      for entry in ranges {
        let (lo, hi) = entry
        if tc >= lo && tc <= hi {
          found = true
        }
      }
      if found == negated {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    Digit => {
      if pos >= text.length() || !is_digit(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    NotDigit => {
      if pos >= text.length() || is_digit(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    Word => {
      if pos >= text.length() || !is_word_char(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    NotWord => {
      if pos >= text.length() || is_word_char(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    Space => {
      if pos >= text.length() || !is_space(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    NotSpace => {
      if pos >= text.length() || is_space(text[pos]) {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos + 1, flags)
    }
    WordBoundary => {
      let before = if pos > 0 && pos <= text.length() {
        is_word_char(text[pos - 1])
      } else {
        false
      }
      let after = if pos < text.length() {
        is_word_char(text[pos])
      } else {
        false
      }
      if before == after {
        return None
      }
      match_tokens(tokens, token_idx + 1, text, pos, flags)
    }
    Star(inner) => {
      // 贪心匹配：先算出最大匹配次数
      let mut max_count = 0
      let mut p = pos
      while p < text.length() {
        let len = match_simple_tokens(inner, text, p, flags)
        if len > 0 {
          max_count = max_count + len
          p = p + len
        } else {
          break
        }
      }
      // 从最大匹配开始回退
      let mut c = max_count
      while c >= 0 {
        let rest = match_tokens(tokens, token_idx + 1, text, pos + c, flags)
        match rest {
          Some(_) => return rest
          None => c = c - 1
        }
      }
      None
    }
    Plus(inner) => {
      // 至少匹配一次
      let first_len = match_simple_tokens(inner, text, pos, flags)
      if first_len <= 0 {
        return None
      }
      // 贪心匹配
      let mut max_count = first_len
      let mut p = pos + first_len
      while p < text.length() {
        let len = match_simple_tokens(inner, text, p, flags)
        if len > 0 {
          max_count = max_count + len
          p = p + len
        } else {
          break
        }
      }
      // 从最大匹配开始回退
      let mut c = max_count
      while c >= first_len {
        let rest = match_tokens(tokens, token_idx + 1, text, pos + c, flags)
        match rest {
          Some(_) => return rest
          None => c = c - 1
        }
      }
      None
    }
    Optional(inner) => {
      // 先尝试匹配
      let len = match_simple_tokens(inner, text, pos, flags)
      if len > 0 {
        let rest = match_tokens(tokens, token_idx + 1, text, pos + len, flags)
        match rest {
          Some(_) => return rest
          None => ()
        }
      }
      // 再尝试不匹配
      match_tokens(tokens, token_idx + 1, text, pos, flags)
    }
  }
}

///|
/// 简单匹配一组 token（用于 Star/Plus/Optional 的 inner），返回匹配长度
fn match_simple_tokens(
  tokens : Array[RegexToken],
  text : Array[Char],
  start : Int,
  flags : RegexFlags,
) -> Int {
  match match_tokens(tokens, 0, text, start, flags) {
    Some(end) => end - start
    None => 0
  }
}
