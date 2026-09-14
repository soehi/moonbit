// moonsh_test.mbt — moonsh 黑盒测试
// 测试公共 API 的正确性

///|
test "doctor - complete MoonBit workspace" {
  let report = audit_workspace([
    "moon.mod", "moon.pkg", "README.md", "LICENSE", ".github/workflows/ci.yml", "main.mbt",
    "main_test.mbt", "cmd/main/moon.pkg", "cmd/main/main_test.mbt",
  ])
  assert_eq(report.score, 100)
  assert_eq(report.moonbit_files, 3)
  assert_eq(report.test_files, 2)
  assert_eq(report.packages, 2)
  assert_eq(report.untested_packages, 0)
  assert_eq(audit_grade(report.score), "A")
  assert_true(format_workspace_audit(report).contains("[PASS] tests"))
  assert_true(format_workspace_audit(report).contains("package-tests"))
}

///|
test "doctor - reports missing project essentials" {
  let report = audit_workspace(["src/main.mbt"])
  assert_eq(report.score, 20)
  assert_eq(report.findings.length(), 7)
  assert_eq(audit_grade(report.score), "F")
  assert_true(format_workspace_audit(report).contains("[FAIL] module"))
  assert_true(format_workspace_audit(report).contains("[WARN] tests"))
}

///|
test "doctor - normalizes Windows paths and case" {
  let report = audit_workspace([
    "MOON.MOD", "Moon.Pkg", "README.MD", "LICENSE.txt", ".GITHUB\\WORKFLOWS\\CI.YAML",
    "LIB\\CORE.MBT", "LIB\\CORE_WBTEST.MBT",
  ])
  assert_eq(report.score, 100)
}

///|
test "doctor - detects packages without colocated tests" {
  let report = audit_workspace([
    "moon.mod", "moon.pkg", "README.md", "LICENSE", ".github/workflows/ci.yml", "lib/moon.pkg",
    "main.mbt", "main_test.mbt", "lib/core.mbt",
  ])
  assert_eq(report.score, 100)
  assert_eq(report.untested_packages, 1)
  assert_true(
    format_workspace_audit(report).contains(
      "1 个包没有同目录测试文件",
    ),
  )
}

///|
test "doctor - JSON output" {
  let report = audit_workspace(["moon.mod", "moon.pkg", "main.mbt"])
  let json = format_workspace_audit_json(report)
  assert_true(json.has_prefix("{\"score\":"))
  assert_true(json.contains("\"grade\":\""))
  assert_true(json.contains("\"untestedPackages\":1"))
  assert_true(json.contains("\"severity\":\"warning\""))
}

///|
test "doctor - Markdown and badge output" {
  let report = audit_workspace([
    "moon.mod", "moon.pkg", "README.md", "LICENSE", ".github/workflows/ci.yml", "main.mbt",
    "main_test.mbt",
  ])
  let markdown = format_workspace_audit_markdown(report)
  assert_true(markdown.has_prefix("## Moonsh Doctor"))
  assert_true(markdown.contains("| ✅ | `module` |"))
  let badge = format_workspace_audit_badge(report)
  assert_true(badge.contains("moonsh%20doctor-A%20100%2F100-brightgreen"))
}

///|
test "doctor - grade boundaries" {
  assert_eq(audit_grade(100), "A")
  assert_eq(audit_grade(90), "A")
  assert_eq(audit_grade(89), "B")
  assert_eq(audit_grade(75), "B")
  assert_eq(audit_grade(60), "C")
  assert_eq(audit_grade(40), "D")
  assert_eq(audit_grade(39), "F")
}

///|
test "format_size - bytes" {
  assert_eq(format_size(500L), "500 B")
  assert_eq(format_size(0L), "0 B")
  assert_eq(format_size(1023L), "1023 B")
}

///|
test "format_size - kib" {
  let result = format_size(1024L)
  assert_true(result.contains("KiB"))
  // 1024 -> 1.0 KiB
  assert_eq(result, "1.0 KiB")
}

///|
test "format_size - mib" {
  let result = format_size(1048576L)
  assert_true(result.contains("MiB"))
}

///|
test "format_size_int" {
  let result = format_size_int(2048)
  assert_true(result.contains("KiB"))
}

///|
test "get_extension - normal" {
  assert_eq(get_extension("file.txt"), "txt")
  assert_eq(get_extension("archive.tar.gz"), "gz")
  assert_eq(get_extension("image.PNG"), "png")
}

///|
test "get_extension - no extension" {
  assert_eq(get_extension("README"), "")
  assert_eq(get_extension(".hidden"), "")
  assert_eq(get_extension("file."), "")
}

///|
test "get_extension - with path" {
  assert_eq(get_extension("/usr/local/file.rs"), "rs")
  assert_eq(get_extension("src\\main.mbt"), "mbt")
}

///|
test "get_basename - normal" {
  assert_eq(get_basename("file.txt"), "file")
  assert_eq(get_basename("archive.tar.gz"), "archive.tar")
}

///|
test "get_basename - no extension" {
  assert_eq(get_basename("README"), "README")
}

///|
test "get_basename_from_path" {
  assert_eq(get_basename_from_path("/usr/local/file.txt"), "file.txt")
  assert_eq(get_basename_from_path("src\\main.mbt"), "main.mbt")
  assert_eq(get_basename_from_path("simple.txt"), "simple.txt")
}

///|
test "get_dirname" {
  assert_eq(get_dirname("/usr/local/file.txt"), "/usr/local")
  assert_eq(get_dirname("src\\main.mbt"), "src")
  assert_eq(get_dirname("simple.txt"), ".")
}

///|
test "detect_file_type - code" {
  assert_true(detect_file_type("main.mbt") is Code)
  assert_true(detect_file_type("app.rs") is Code)
  assert_true(detect_file_type("script.py") is Code)
  assert_true(detect_file_type("index.js") is Code)
}

///|
test "detect_file_type - archive" {
  assert_true(detect_file_type("backup.zip") is Archive)
  assert_true(detect_file_type("data.tar.gz") is Archive)
}

///|
test "detect_file_type - image" {
  assert_true(detect_file_type("photo.png") is Image)
  assert_true(detect_file_type("pic.jpg") is Image)
}

///|
test "detect_file_type - doc" {
  assert_true(detect_file_type("readme.md") is Doc)
  assert_true(detect_file_type("doc.pdf") is Doc)
}

///|
test "detect_file_type - other" {
  assert_true(detect_file_type("unknown.xyz") is Other)
  assert_true(detect_file_type("noext") is Regular)
}

///|
test "pad_right" {
  assert_eq(pad_right("hi", 5), "hi   ")
  assert_eq(pad_right("hello", 3), "hello")
  assert_eq(pad_right("", 3), "   ")
}

///|
test "pad_left" {
  assert_eq(pad_left("42", 5), "   42")
  assert_eq(pad_left("hello", 3), "hello")
}

///|
test "repeat_char" {
  assert_eq(repeat_char('-', 5), "-----")
  assert_eq(repeat_char('*', 0), "")
  assert_eq(repeat_char('a', 3), "aaa")
}

///|
test "repeat_str" {
  assert_eq(repeat_str("ab", 3), "ababab")
  assert_eq(repeat_str("x", 0), "")
}

///|
test "split_lines - basic" {
  let lines = split_lines("a\nb\nc")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
  assert_eq(lines[2], "c")
}

///|
test "split_lines - empty" {
  let lines = split_lines("")
  assert_eq(lines.length(), 0)
}

///|
test "split_lines - single line" {
  let lines = split_lines("hello")
  assert_eq(lines.length(), 1)
  assert_eq(lines[0], "hello")
}

///|
test "split_lines - trailing newline" {
  let lines = split_lines("a\nb\n")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
  assert_eq(lines[2], "")
}

///|
test "split_lines - windows line endings" {
  let lines = split_lines("a\r\nb\r\n")
  assert_eq(lines.length(), 3)
  assert_eq(lines[0], "a")
  assert_eq(lines[1], "b")
}

///|
test "count_text - basic" {
  let result = count_text("hello world")
  assert_eq(result.lines, 1)
  assert_eq(result.words, 2)
  assert_eq(result.chars, 11)
}

///|
test "count_text - multiline" {
  let result = count_text("a\nb\nc\n")
  assert_eq(result.lines, 3)
  assert_eq(result.words, 3)
}

///|
test "count_text - empty" {
  let result = count_text("")
  assert_eq(result.lines, 0)
  assert_eq(result.words, 0)
  assert_eq(result.chars, 0)
}

///|
test "count_text - no trailing newline" {
  let result = count_text("hello\nworld")
  assert_eq(result.lines, 2)
}

///|
test "format_permissions" {
  let perm = format_permissions(0x4000 | 0o755)
  assert_eq(perm, "drwxr-xr-x")
}

///|
test "format_permissions - regular file" {
  let perm = format_permissions(0o644)
  assert_eq(perm, "-rw-r--r--")
}

///|
test "char_to_lower" {
  assert_eq(char_to_lower('A'), 'a')
  assert_eq(char_to_lower('Z'), 'z')
  assert_eq(char_to_lower('a'), 'a')
  assert_eq(char_to_lower('1'), '1')
}

///|
test "char_to_upper" {
  assert_eq(char_to_upper('a'), 'A')
  assert_eq(char_to_upper('z'), 'Z')
  assert_eq(char_to_upper('A'), 'A')
}

///|
test "is_digit" {
  assert_true(is_digit('0'))
  assert_true(is_digit('9'))
  assert_false(is_digit('a'))
}

///|
test "is_word_char" {
  assert_true(is_word_char('a'))
  assert_true(is_word_char('Z'))
  assert_true(is_word_char('0'))
  assert_true(is_word_char('_'))
  assert_false(is_word_char('-'))
  assert_false(is_word_char(' '))
}

///|
test "is_space" {
  assert_true(is_space(' '))
  assert_true(is_space('\t'))
  assert_true(is_space('\n'))
  assert_false(is_space('a'))
}

///|
test "is_alpha" {
  assert_true(is_alpha('a'))
  assert_true(is_alpha('Z'))
  assert_false(is_alpha('0'))
  assert_false(is_alpha('_'))
}

///|
test "format_timestamp - epoch" {
  let ts = format_timestamp(0L)
  assert_eq(ts, "1970-01-01 00:00:00")
}

///|
test "format_timestamp - known" {
  // 2024-01-01 00:00:00 = 1704067200
  let ts = format_timestamp(1704067200L)
  assert_eq(ts, "2024-01-01 00:00:00")
}

///|
test "parse_int_safe - valid" {
  assert_eq(parse_int_safe("42", 0), 42)
  assert_eq(parse_int_safe("0", 0), 0)
  assert_eq(parse_int_safe("-5", 0), -5)
}

///|
test "parse_int_safe - invalid" {
  assert_eq(parse_int_safe("abc", 42), 42)
  assert_eq(parse_int_safe("", 42), 42)
}

///|
test "get_flag - present" {
  let m : Map[String, Bool] = Map([])
  m["all"] = true
  assert_true(get_flag(m, "all"))
}

///|
test "get_flag - absent" {
  let m : Map[String, Bool] = Map([])
  assert_false(get_flag(m, "all"))
}

///|
test "get_positional - present" {
  let m : Map[String, Array[String]] = Map([])
  m["path"] = ["/tmp"]
  assert_eq(get_positional(m, "path", "."), "/tmp")
}

///|
test "get_positional - default" {
  let m : Map[String, Array[String]] = Map([])
  assert_eq(get_positional(m, "path", "."), ".")
}

///|
test "supported_commands" {
  let cmds = supported_commands()
  assert_eq(cmds.length(), 15)
  assert_eq(cmds[0], "ls")
  assert_eq(cmds[7], "stat")
  assert_eq(cmds[8], "sort")
  assert_eq(cmds[12], "diff")
  assert_eq(cmds[13], "md")
  assert_eq(cmds[14], "doctor")
}

///|
test "moonsh_version" {
  assert_eq(moonsh_version, "0.3.0")
}

// ============================================================
// path 模块测试
// ============================================================

///|
test "is_absolute_path - unix absolute" {
  assert_true(is_absolute_path("/home/user"))
}

///|
test "is_absolute_path - relative" {
  assert_false(is_absolute_path("home/user"))
}

///|
test "is_absolute_path - empty" {
  assert_false(is_absolute_path(""))
}

///|
test "is_relative_path - relative" {
  assert_true(is_relative_path("foo/bar"))
}

///|
test "normalize_separators - backslash to slash" {
  assert_eq(normalize_separators("a\\b\\c"), "a/b/c")
}

///|
test "normalize_separators - already normalized" {
  assert_eq(normalize_separators("a/b/c"), "a/b/c")
}

///|
test "join_paths - simple" {
  assert_eq(join_paths("a", "b"), "a/b")
}

///|
test "join_paths - with trailing slash" {
  assert_eq(join_paths("a/", "b"), "a/b")
}

///|
test "join_paths - child absolute" {
  assert_eq(join_paths("a", "/b"), "/b")
}

///|
test "normalize_path - with dot" {
  assert_eq(normalize_path("a/./b"), "a/b")
}

///|
test "normalize_path - with dot dot" {
  assert_eq(normalize_path("a/../b"), "b")
}

///|
test "split_path_segments - simple" {
  let segs = split_path_segments("a/b/c")
  assert_eq(segs.length(), 3)
  assert_eq(segs[0], "a")
}

///|
test "parent_dir - simple" {
  assert_eq(parent_dir("/a/b/c"), "/a/b")
}

///|
test "parent_dir - root" {
  assert_eq(parent_dir("/a"), "/")
}

///|
test "path_filename - simple" {
  assert_eq(path_filename("/a/b/c.txt"), "c.txt")
}

///|
test "path_extension - txt" {
  assert_eq(path_extension("file.txt"), ".txt")
}

///|
test "path_extension - no extension" {
  assert_eq(path_extension("README"), "")
}

///|
test "remove_extension - simple" {
  assert_eq(remove_extension("file.txt"), "file")
}

///|
test "replace_extension - simple" {
  assert_eq(replace_extension("file.txt", "md"), "file.md")
}

///|
test "path_depth - simple" {
  assert_eq(path_depth("/a/b/c"), 3)
}

///|
test "join_path_multi - multiple" {
  assert_eq(join_path_multi(["a", "b", "c"]), "a/b/c")
}

///|
test "is_path_inside - inside" {
  assert_true(is_path_inside("/a/b/c", "/a/b"))
}

///|
test "is_path_inside - not inside" {
  assert_false(is_path_inside("/a/b", "/x/y"))
}

///|
test "path_has_suffix - true" {
  assert_true(path_has_suffix("file.txt", ".txt"))
}

///|
test "path_has_prefix - true" {
  assert_true(path_has_prefix("/home/user", "/home"))
}

// ============================================================
// sort 模块测试
// ============================================================

///|
test "sort_lines - lexical" {
  let opts : SortOptions = SortOptions::default()
  let result = sort_lines(["banana", "apple", "cherry"], opts)
  assert_eq(result[0], "apple")
  assert_eq(result[1], "banana")
  assert_eq(result[2], "cherry")
}

///|
test "sort_lines - reverse" {
  // struct update not available in blackbox tests
  // See whitebox tests for reverse/unique/ignore_case tests
  let opts : SortOptions = SortOptions::default()
  let result = sort_lines(["cherry", "apple", "banana"], opts)
  assert_eq(result[0], "apple")
  assert_eq(result[1], "banana")
  assert_eq(result[2], "cherry")
}

///|
test "sort_lines - unique" {
  // Unique filtering tested in whitebox tests
  let opts : SortOptions = SortOptions::default()
  let result = sort_lines(["apple", "banana", "cherry"], opts)
  assert_eq(result.length(), 3)
}

///|
test "sort_lines - ignore_case" {
  // Ignore case tested in whitebox tests
  let opts : SortOptions = SortOptions::default()
  let result = sort_lines(["apple", "banana", "cherry"], opts)
  assert_eq(result[0], "apple")
}

// ============================================================
// diff 模块测试
// ============================================================

///|
test "diff_text - identical" {
  let result = diff_text("hello\nworld", "hello\nworld")
  assert_eq(result.added, 0)
  assert_eq(result.deleted, 0)
}

///|
test "diff_text - addition" {
  let result = diff_text("a\nb", "a\nb\nc")
  assert_eq(result.added, 1)
}

///|
test "diff_text - deletion" {
  let result = diff_text("a\nb\nc", "a\nb")
  assert_eq(result.deleted, 1)
}

///|
test "text_equal - same" {
  assert_true(text_equal("hello", "hello"))
}

///|
test "text_equal - different" {
  assert_false(text_equal("hello", "world"))
}

///|
test "diff_summary - format" {
  let result = diff_text("a", "b")
  let summary = diff_summary(result)
  assert_true(summary.contains("additions"))
}

// ============================================================
// cut 模块测试
// ============================================================

///|
test "parse_positions - single" {
  let positions = parse_positions("3")
  assert_eq(positions.length(), 1)
  assert_eq(positions[0].0, 3)
  assert_eq(positions[0].1, 3)
}

///|
test "parse_positions - range" {
  let positions = parse_positions("1-3")
  assert_eq(positions.length(), 1)
  assert_eq(positions[0].0, 1)
  assert_eq(positions[0].1, 3)
}

///|
test "parse_positions - multiple" {
  let positions = parse_positions("1,3,5")
  assert_eq(positions.length(), 3)
}

// ============================================================
// tr 模块测试
// ============================================================

///|
test "parse_charset - simple chars" {
  let set = parse_charset("abc")
  assert_eq(set.chars.length(), 3)
}

///|
test "parse_charset - range" {
  let set = parse_charset("a-z")
  assert_eq(set.ranges.length(), 1)
}

///|
test "char_in_set - in range" {
  let set = parse_charset("a-z")
  assert_true(char_in_set('m', set))
}

///|
test "char_in_set - not in range" {
  let set = parse_charset("a-z")
  assert_false(char_in_set('Z', set))
}

///|
test "charset_size - simple" {
  let set = parse_charset("abc")
  assert_eq(charset_size(set), 3)
}

///|
test "charset_size - range" {
  let set = parse_charset("a-z")
  assert_eq(charset_size(set), 26)
}

// ============================================================
// uniq 模块测试
// ============================================================

///|
test "uniq_lines - basic" {
  let opts : UniqOptions = UniqOptions::default()
  let result = uniq_lines(["a", "a", "b", "b", "c"], opts)
  assert_eq(result.length(), 3)
  assert_eq(result[0], "a")
  assert_eq(result[1], "b")
  assert_eq(result[2], "c")
}

///|
test "uniq_lines - count" {
  // count option tested in whitebox tests
  let opts : UniqOptions = UniqOptions::default()
  let result = uniq_lines(["a", "a", "b"], opts)
  assert_eq(result.length(), 2)
}

///|
test "uniq_lines - only unique" {
  // only_unique tested in whitebox tests
  let opts : UniqOptions = UniqOptions::default()
  let result = uniq_lines(["a", "b", "c"], opts)
  assert_eq(result.length(), 3)
}

///|
test "uniq_lines - only duplicate" {
  // only_duplicate tested in whitebox tests
  let opts : UniqOptions = UniqOptions::default()
  let result = uniq_lines(["a", "a", "b"], opts)
  assert_eq(result.length(), 2)
}

// ============================================================
// markdown 模块测试
// ============================================================

///|
test "escape_html - basic" {
  assert_eq(escape_html("a < b"), "a &lt; b")
  assert_eq(escape_html("a & b"), "a &amp; b")
  assert_eq(escape_html("x > y"), "x &gt; y")
}

///|
test "escape_html - quotes" {
  assert_eq(escape_html("a\"b"), "a&quot;b")
}

///|
test "parse_inline - plain text" {
  let result = parse_inline("hello world")
  assert_eq(result.length(), 1)
  assert_true(result[0] is PlainText("hello world"))
}

///|
test "parse_inline - bold with **" {
  let result = parse_inline("**bold**")
  assert_eq(result.length(), 1)
  assert_true(result[0] is StrongEmphasis("bold"))
}

///|
test "parse_inline - italic with *" {
  let result = parse_inline("*italic*")
  assert_eq(result.length(), 1)
  assert_true(result[0] is Emphasis("italic"))
}

///|
test "parse_inline - inline code" {
  let result = parse_inline("`code`")
  assert_eq(result.length(), 1)
  assert_true(result[0] is Code("code"))
}

///|
test "parse_inline - link" {
  let result = parse_inline("[text](url)")
  assert_eq(result.length(), 1)
  assert_true(result[0] is Link("text", "url"))
}

///|
test "parse_inline - image" {
  let result = parse_inline("![alt](img.png)")
  assert_eq(result.length(), 1)
  assert_true(result[0] is Image("alt", "img.png"))
}

///|
test "parse_inline - strikethrough" {
  let result = parse_inline("~~deleted~~")
  assert_eq(result.length(), 1)
  assert_true(result[0] is Strikethrough("deleted"))
}

///|
test "parse_inline - mixed" {
  let result = parse_inline("hello **bold** world")
  assert_eq(result.length(), 3)
  assert_true(result[0] is PlainText("hello "))
  assert_true(result[1] is StrongEmphasis("bold"))
  assert_true(result[2] is PlainText(" world"))
}

///|
test "markdown_to_html - heading" {
  let html = markdown_to_html("# Hello")
  assert_eq(html, "<h1>Hello</h1>\n")
}

///|
test "markdown_to_html - paragraph" {
  let html = markdown_to_html("Hello world")
  assert_eq(html, "<p>Hello world</p>\n")
}

///|
test "markdown_to_html - bold and italic" {
  let html = markdown_to_html("**bold** and *italic*")
  assert_true(html.contains("<strong>bold</strong>"))
  assert_true(html.contains("<em>italic</em>"))
}

///|
test "markdown_to_html - code block" {
  let html = markdown_to_html("```\nlet x = 1\n```")
  assert_true(html.contains("<pre><code>"))
  assert_true(html.contains("let x = 1"))
}

///|
test "markdown_to_html - code block with language" {
  let html = markdown_to_html("```rust\nfn main() {}\n```")
  assert_true(html.contains("language-rust"))
}

///|
test "markdown_to_html - link" {
  let html = markdown_to_html("[click](https://example.com)")
  assert_true(html.contains("<a href=\"https://example.com\">click</a>"))
}

///|
test "markdown_to_html - image" {
  let html = markdown_to_html("![alt](img.png)")
  assert_true(html.contains("<img src=\"img.png\" alt=\"alt\" />"))
}

///|
test "markdown_to_html - unordered list" {
  let html = markdown_to_html("- item1\n- item2")
  assert_true(html.contains("<ul>"))
  assert_true(html.contains("<li>"))
  assert_true(html.contains("item1"))
  assert_true(html.contains("item2"))
}

///|
test "markdown_to_html - ordered list" {
  let html = markdown_to_html("1. first\n2. second")
  assert_true(html.contains("<ol>"))
  assert_true(html.contains("first"))
  assert_true(html.contains("second"))
}

///|
test "markdown_to_html - blockquote" {
  let html = markdown_to_html("> quoted text")
  assert_true(html.contains("<blockquote>"))
  assert_true(html.contains("quoted text"))
}

///|
test "markdown_to_html - thematic break" {
  let html = markdown_to_html("---")
  assert_eq(html, "<hr />\n")
}

///|
test "markdown_to_html - table" {
  let md = "| A | B |\n|---|---|\n| 1 | 2 |"
  let html = markdown_to_html(md)
  assert_true(html.contains("<table>"))
  assert_true(html.contains("<th>A</th>"))
  assert_true(html.contains("<td>1</td>"))
}

///|
test "markdown_to_html - multiple blocks" {
  let md = "# Title\n\nParagraph\n\n- list"
  let html = markdown_to_html(md)
  assert_true(html.contains("<h1>"))
  assert_true(html.contains("<p>"))
  assert_true(html.contains("<ul>"))
}

///|
test "md_render - alias" {
  let html = md_render("# Hi")
  assert_eq(html, "<h1>Hi</h1>\n")
}

///|
test "md_render_with_options - no wrap" {
  let opts = MarkdownOptions::default()
  let html = md_render_with_options("# Hi", opts)
  assert_eq(html, "<h1>Hi</h1>\n")
}
