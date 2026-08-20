// moonsh_wbtest.mbt — moonsh 白盒测试
// 测试内部函数（glob 匹配、正则引擎等）

///|
test "glob_match - star" {
  assert_true(glob_match("*.txt", "hello.txt"))
  assert_true(glob_match("*.txt", "file.txt"))
  assert_false(glob_match("*.txt", "file.rs"))
}

///|
test "glob_match - question mark" {
  assert_true(glob_match("?.txt", "a.txt"))
  assert_true(glob_match("??.txt", "ab.txt"))
  assert_false(glob_match("?.txt", "ab.txt"))
}

///|
test "glob_match - exact" {
  assert_true(glob_match("hello.txt", "hello.txt"))
  assert_false(glob_match("hello.txt", "world.txt"))
}

///|
test "glob_match - bracket" {
  assert_true(glob_match("[abc].txt", "a.txt"))
  assert_true(glob_match("[abc].txt", "b.txt"))
  assert_true(glob_match("[abc].txt", "c.txt"))
  assert_false(glob_match("[abc].txt", "d.txt"))
}

///|
test "glob_match - range" {
  assert_true(glob_match("[a-z].txt", "x.txt"))
  assert_true(glob_match("[0-9].txt", "5.txt"))
  assert_false(glob_match("[a-z].txt", "1.txt"))
}

///|
test "glob_match - negated bracket" {
  assert_true(glob_match("[!abc].txt", "d.txt"))
  assert_false(glob_match("[!abc].txt", "a.txt"))
}

///|
test "glob_match - double star" {
  assert_true(glob_match("src/**/*.mbt", "src/a/b.mbt"))
  assert_true(glob_match("src/**/*.mbt", "src/a/b/c.mbt"))
  assert_true(glob_match("src/**/*.mbt", "src/main.mbt"))
  assert_false(glob_match("src/**/*.mbt", "test/main.mbt"))
}

///|
test "glob_match - star in name" {
  assert_true(glob_match("test*.mbt", "test_foo.mbt"))
  assert_true(glob_match("test*.mbt", "test.mbt"))
}

///|
test "glob_match - no slash in star" {
  assert_false(glob_match("*", "a/b"))
  assert_true(glob_match("*", "abc"))
}

///|
test "regex_match - literal" {
  assert_true(regex_match("hello", "hello world"))
  assert_false(regex_match("hello", "world foo"))
}

///|
test "regex_match - dot" {
  assert_true(regex_match("h.llo", "hello"))
  assert_true(regex_match("h.llo", "hallo"))
  assert_false(regex_match("h.llo", "hllo"))
}

///|
test "regex_match - star" {
  assert_true(regex_match("ab*c", "ac"))
  assert_true(regex_match("ab*c", "abc"))
  assert_true(regex_match("ab*c", "abbbbc"))
  assert_false(regex_match("ab*c", "ab"))
}

///|
test "regex_match - plus" {
  assert_true(regex_match("ab+c", "abc"))
  assert_true(regex_match("ab+c", "abbbbc"))
  assert_false(regex_match("ab+c", "ac"))
}

///|
test "regex_match - optional" {
  assert_true(regex_match("colou?r", "color"))
  assert_true(regex_match("colou?r", "colour"))
  assert_false(regex_match("colou?r", "colouur"))
}

///|
test "regex_match - anchored start" {
  assert_true(regex_match("^hello", "hello world"))
  assert_false(regex_match("^hello", "world hello"))
}

///|
test "regex_match - anchored end" {
  assert_true(regex_match("world$", "hello world"))
  assert_false(regex_match("world$", "world hello"))
}

///|
test "regex_match - digit class" {
  assert_true(regex_match("\\d", "a1b"))
  assert_true(regex_match("\\d\\d", "ab12cd"))
  assert_false(regex_match("\\d", "abc"))
}

///|
test "regex_match - word char" {
  assert_true(regex_match("\\w", "hello"))
  assert_true(regex_match("\\w", "test_123"))
  assert_false(regex_match("\\w", " "))
}

///|
test "regex_match - space" {
  assert_true(regex_match("a\\sb", "a b"))
  assert_true(regex_match("a\\sb", "a\tb"))
  assert_false(regex_match("a\\sb", "axb"))
}

///|
test "regex_match - char class" {
  assert_true(regex_match("[abc]", "xby"))
  assert_true(regex_match("[a-z]", "xyz"))
  assert_false(regex_match("[a-z]", "123"))
}

///|
test "regex_find - multiple matches" {
  let positions = regex_find("a", "banana")
  assert_eq(positions.length(), 3)
  assert_eq(positions[0], 1)
  assert_eq(positions[1], 3)
  assert_eq(positions[2], 5)
}

///|
test "regex_find - no match" {
  let positions = regex_find("xyz", "hello world")
  assert_eq(positions.length(), 0)
}

///|
test "regex_find_flags - ignore case" {
  let flags = { ignore_case: true, multiline: false }
  let positions = regex_find_flags("hello", "HELLO world", flags)
  assert_eq(positions.length(), 1)
}

///|
test "regex_match - complex pattern" {
  assert_true(regex_match("a.*c", "axxxc"))
  assert_true(regex_match("a.*c", "abc"))
  assert_true(regex_match("a.*c", "a123456c"))
}

///|
test "colorize - wraps with ansi" {
  let result = colorize("hello", Red)
  assert_true(result.contains("hello"))
  assert_true(result.length() > 5)
}

///|
test "file_type_color" {
  assert_true(file_type_color(Directory) is Blue)
  assert_true(file_type_color(Code) is Cyan)
  assert_true(file_type_color(Archive) is Red)
}

///|
test "file_type_icon" {
  let icon = file_type_icon(Directory)
  assert_true(icon.length() > 0)
}

// ============================================================
// sort 模块白盒测试
// ============================================================

///|
test "sort_lines - reverse" {
  let opts : SortOptions = { ..SortOptions::default(), reverse: true }
  let result = sort_lines(["apple", "banana", "cherry"], opts)
  assert_eq(result[0], "cherry")
  assert_eq(result[2], "apple")
}

///|
test "sort_lines - unique" {
  let opts : SortOptions = { ..SortOptions::default(), unique: true }
  let result = sort_lines(["a", "b", "a", "c", "b"], opts)
  assert_eq(result.length(), 3)
  assert_eq(result[0], "a")
  assert_eq(result[1], "b")
  assert_eq(result[2], "c")
}

///|
test "sort_lines - ignore_case" {
  let opts : SortOptions = { ..SortOptions::default(), ignore_case: true }
  let result = sort_lines(["Banana", "apple", "Cherry"], opts)
  assert_eq(result[0], "apple")
}

///|
test "sort_lines - numeric" {
  let opts : SortOptions = { ..SortOptions::default(), mode: Numeric }
  let result = sort_lines(["10", "2", "1", "20"], opts)
  assert_eq(result[0], "1")
  assert_eq(result[1], "2")
  assert_eq(result[2], "10")
  assert_eq(result[3], "20")
}

///|
test "sort_lines - natural" {
  let opts : SortOptions = { ..SortOptions::default(), mode: Natural }
  let result = sort_lines(["file10", "file2", "file1"], opts)
  assert_eq(result[0], "file1")
  assert_eq(result[1], "file2")
  assert_eq(result[2], "file10")
}

// ============================================================
// uniq 模块白盒测试
// ============================================================

///|
test "uniq_lines - count" {
  let opts : UniqOptions = { ..UniqOptions::default(), count: true }
  let result = uniq_lines(["a", "a", "b"], opts)
  assert_eq(result.length(), 2)
  assert_true(result[0].contains("a"))
}

///|
test "uniq_lines - only unique" {
  let opts : UniqOptions = { ..UniqOptions::default(), only_unique: true }
  let result = uniq_lines(["a", "a", "b", "c", "c"], opts)
  assert_eq(result.length(), 1)
  assert_eq(result[0], "b")
}

///|
test "uniq_lines - only duplicate" {
  let opts : UniqOptions = { ..UniqOptions::default(), only_duplicate: true }
  let result = uniq_lines(["a", "a", "b", "c", "c"], opts)
  assert_eq(result.length(), 2)
}

///|
test "uniq_lines - ignore_case" {
  let opts : UniqOptions = { ..UniqOptions::default(), ignore_case: true }
  let result = uniq_lines(["Hello", "hello", "World"], opts)
  assert_eq(result.length(), 2)
}

// ============================================================
// tr 模块白盒测试
// ============================================================

///|
test "tr_translate - basic replace" {
  let from = parse_charset("abc")
  let to = parse_charset("xyz")
  let opts : TrOptions = TrOptions::default()
  let result = tr_translate("abcdef", from, to, opts)
  assert_eq(result, "xyzdef")
}

///|
test "tr_translate - delete" {
  let from = parse_charset("aeiou")
  let to = parse_charset("")
  let opts : TrOptions = { ..TrOptions::default(), delete: true }
  let result = tr_translate("hello world", from, to, opts)
  assert_eq(result, "hll wrld")
}

///|
test "tr_translate - upper to lower" {
  let from = parse_charset("A-Z")
  let to = parse_charset("a-z")
  let opts : TrOptions = TrOptions::default()
  let result = tr_translate("HELLO", from, to, opts)
  assert_eq(result, "hello")
}

// ============================================================
// cut 模块白盒测试
// ============================================================

///|
test "cut_line - field" {
  let mode = Field(",", [(2, 2)])
  let result = cut_line("a,b,c,d", mode)
  assert_eq(result, "b")
}

///|
test "cut_line - char positions" {
  let mode = CharPositions([(1, 3)])
  let result = cut_line("hello world", mode)
  assert_eq(result, "hel")
}

///|
test "cut_lines - multiple" {
  let mode = Field(",", [(1, 2)])
  let result = cut_lines(["a,b,c", "d,e,f"], mode)
  assert_eq(result.length(), 2)
  assert_eq(result[0], "a,b")
}

// ============================================================
// diff 模块白盒测试
// ============================================================

///|
test "diff_lines - mixed changes" {
  let result = diff_lines(["a", "b", "c"], ["a", "x", "c"])
  assert_eq(result.added, 1)
  assert_eq(result.deleted, 1)
}

///|
test "diff_lines - all new" {
  let result = diff_lines([], ["a", "b"])
  assert_eq(result.added, 2)
}

///|
test "diff_lines - all deleted" {
  let result = diff_lines(["a", "b"], [])
  assert_eq(result.deleted, 2)
}

///|
test "count_diff - values" {
  let result = diff_text("a\nb\nc", "a\nx\nc")
  let (added, deleted, _) = count_diff(result)
  assert_eq(added, 1)
  assert_eq(deleted, 1)
}

///|
test "format_diff - contains markers" {
  let result = diff_text("a\nb", "a\nc")
  let formatted = format_diff(result)
  assert_true(formatted.contains("- "))
  assert_true(formatted.contains("+ "))
}

// ============================================================
// path 模块白盒测试
// ============================================================

///|
test "path_type - absolute unix" {
  assert_true(path_type("/home") is Absolute)
}

///|
test "path_type - relative" {
  assert_true(path_type("foo/bar") is Relative)
}

///|
test "path_type - home" {
  assert_true(path_type("~/home") is HomeRelative)
}

///|
test "normalize_path - root" {
  assert_eq(normalize_path("/"), "/")
}

///|
test "path_ancestors - simple" {
  let ancestors = path_ancestors("/a/b/c")
  assert_true(ancestors.length() > 0)
}

///|
test "relative_path - simple" {
  assert_eq(relative_path("/a/b", "/a/b/c"), "c")
}

///|
test "strip_trailing_sep - simple" {
  assert_eq(strip_trailing_sep("a/b/"), "a/b")
}

///|
test "path_extension - hidden file" {
  assert_eq(path_extension(".gitignore"), "")
}
