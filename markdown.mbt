// markdown.mbt - Markdown 解析器和 HTML 渲染器
// 支持标题、段落、列表、代码块、引用、链接、图片、粗体、斜体、删除线

///|
/// Markdown AST 节点类型
pub enum InlineElement {
  PlainText(String)
  Emphasis(String)
  StrongEmphasis(String)
  Code(String)
  Link(String, String)
  Image(String, String)
  Strikethrough(String)
}

pub enum BlockElement {
  Heading(Int, Array[InlineElement])
  Paragraph(Array[InlineElement])
  Blockquote(Array[BlockElement])
  CodeBlock(String, String)
  UnorderedList(Array[ListItem])
  OrderedList(Array[ListItem])
  Table(Array[Array[InlineElement]], Array[Array[Array[InlineElement]]])
  ThematicBreak
  EmptyLine
}

pub struct ListItem {
  blocks : Array[BlockElement]
}

pub struct Document {
  blocks : Array[BlockElement]
}

///|
/// 转义 HTML 特殊字符
pub fn escape_html(text : String) -> String {
  let result = StringBuilder::new()
  for ch in text {
    match ch {
      '&' => result.write_string("&amp;")
      '<' => result.write_string("&lt;")
      '>' => result.write_string("&gt;")
      '"' => result.write_string("&quot;")
      _ => result.write_char(ch)
    }
  }
  result.to_string()
}

///|
/// 解析内联元素（链接、图片、粗体、斜体等）
pub fn parse_inline(text : String) -> Array[InlineElement] {
  let elements = Array::new()
  let buf = Ref(StringBuilder::new())
  let i = Ref(0)
  let len = text.length()
  // 转为字符数组以便按索引访问
  let chars = Ref(Array::new())
  for c in text {
    chars.val.push(c)
  }

  while i.val < len {
    let c = chars.val[i.val]

    if c == '*' && i.val + 1 < len && chars.val[i.val + 1] == '*' {
      // 保存累积的文本
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      // 解析粗体
      i.val = i.val + 2
      let bold_text = StringBuilder::new()
      while i.val < len && chars.val[i.val] != '*' {
        bold_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      elements.push(StrongEmphasis(bold_text.to_string()))
    } else if c == '_' && i.val + 1 < len && chars.val[i.val + 1] == '_' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 2
      let bold_text = StringBuilder::new()
      while i.val < len && chars.val[i.val] != '_' {
        bold_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      elements.push(StrongEmphasis(bold_text.to_string()))
    } else if c == '*' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 1
      let italic_text = StringBuilder::new()
      while i.val < len && chars.val[i.val] != '*' {
        italic_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      elements.push(Emphasis(italic_text.to_string()))
    } else if c == '_' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 1
      let italic_text = StringBuilder::new()
      while i.val < len && chars.val[i.val] != '_' {
        italic_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      elements.push(Emphasis(italic_text.to_string()))
    } else if c == '`' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 1
      let code_text = StringBuilder::new()
      while i.val < len && chars.val[i.val] != '`' {
        code_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      elements.push(Code(code_text.to_string()))
    } else if c == '~' && i.val + 1 < len && chars.val[i.val + 1] == '~' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 2
      let strike_text = StringBuilder::new()
      while i.val < len {
        if chars.val[i.val] == '~' && i.val + 1 < len && chars.val[i.val + 1] == '~' {
          break
        }
        strike_text.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 2
      }
      elements.push(Strikethrough(strike_text.to_string()))
    } else if c == '!' && i.val + 1 < len && chars.val[i.val + 1] == '[' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 2
      let alt = StringBuilder::new()
      while i.val < len && chars.val[i.val] != ']' {
        alt.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      let url = StringBuilder::new()
      if i.val < len && chars.val[i.val] == '(' {
        i.val = i.val + 1
        while i.val < len && chars.val[i.val] != ')' {
          url.write_char(chars.val[i.val])
          i.val = i.val + 1
        }
        if i.val < len {
          i.val = i.val + 1
        }
      }
      elements.push(Image(alt.to_string(), url.to_string()))
    } else if c == '[' {
      if buf.val.to_string().length() > 0 {
        elements.push(PlainText(buf.val.to_string()))
        buf.val = StringBuilder::new()
      }
      i.val = i.val + 1
      let text_buf = StringBuilder::new()
      while i.val < len && chars.val[i.val] != ']' {
        text_buf.write_char(chars.val[i.val])
        i.val = i.val + 1
      }
      if i.val < len {
        i.val = i.val + 1
      }
      let url = StringBuilder::new()
      if i.val < len && chars.val[i.val] == '(' {
        i.val = i.val + 1
        while i.val < len && chars.val[i.val] != ')' {
          url.write_char(chars.val[i.val])
          i.val = i.val + 1
        }
        if i.val < len {
          i.val = i.val + 1
        }
      }
      elements.push(Link(text_buf.to_string(), url.to_string()))
    } else {
      buf.val.write_char(c)
      i.val = i.val + 1
    }
  }

  if buf.val.to_string().length() > 0 {
    elements.push(PlainText(buf.val.to_string()))
  }

  elements
}

///|
/// 渲染内联元素为 HTML
pub fn render_inline_elements(elements : Array[InlineElement]) -> String {
  let html = StringBuilder::new()
  for elem in elements {
    match elem {
      PlainText(text) => html.write_string(escape_html(text))
      Emphasis(text) => {
        html.write_string("<em>")
        html.write_string(escape_html(text))
        html.write_string("</em>")
      }
      StrongEmphasis(text) => {
        html.write_string("<strong>")
        html.write_string(escape_html(text))
        html.write_string("</strong>")
      }
      Code(text) => {
        html.write_string("<code>")
        html.write_string(escape_html(text))
        html.write_string("</code>")
      }
      Link(text, url) => {
        html.write_string("<a href=\"")
        html.write_string(escape_html(url))
        html.write_string("\">")
        html.write_string(escape_html(text))
        html.write_string("</a>")
      }
      Image(alt, url) => {
        html.write_string("<img src=\"")
        html.write_string(escape_html(url))
        html.write_string("\" alt=\"")
        html.write_string(escape_html(alt))
        html.write_string("\" />")
      }
      Strikethrough(text) => {
        html.write_string("<del>")
        html.write_string(escape_html(text))
        html.write_string("</del>")
      }
    }
  }
  html.to_string()
}

///|
/// 渲染块级元素为 HTML
pub fn render_block(block : BlockElement) -> String {
  match block {
    Heading(level, elements) => {
      let tag = "h" + Int::to_string(level)
      let content = render_inline_elements(elements)
      "<" + tag + ">" + content + "</" + tag + ">\n"
    }
    Paragraph(elements) => {
      let content = render_inline_elements(elements)
      "<p>" + content + "</p>\n"
    }
    Blockquote(blocks) => {
      let content = render_blocks(blocks)
      "<blockquote>\n" + content + "</blockquote>\n"
    }
    CodeBlock(language, code) => {
      let lang_attr = if language.length() > 0 {
        " class=\"language-" + escape_html(language) + "\""
      } else {
        ""
      }
      "<pre><code" + lang_attr + ">" + escape_html(code) + "</code></pre>\n"
    }
    UnorderedList(items) => {
      let html = StringBuilder::new()
      html.write_string("<ul>\n")
      for item in items {
        html.write_string("<li>\n")
        html.write_string(render_blocks(item.blocks))
        html.write_string("</li>\n")
      }
      html.write_string("</ul>\n")
      html.to_string()
    }
    OrderedList(items) => {
      let html = StringBuilder::new()
      html.write_string("<ol>\n")
      for item in items {
        html.write_string("<li>\n")
        html.write_string(render_blocks(item.blocks))
        html.write_string("</li>\n")
      }
      html.write_string("</ol>\n")
      html.to_string()
    }
    Table(headers, rows) => {
      let html = StringBuilder::new()
      html.write_string("<table>\n<thead>\n<tr>\n")
      for header in headers {
        html.write_string("<th>")
        html.write_string(render_inline_elements(header))
        html.write_string("</th>\n")
      }
      html.write_string("</tr>\n</thead>\n<tbody>\n")
      for row in rows {
        html.write_string("<tr>\n")
        for cell in row {
          html.write_string("<td>")
          html.write_string(render_inline_elements(cell))
          html.write_string("</td>\n")
        }
        html.write_string("</tr>\n")
      }
      html.write_string("</tbody>\n</table>\n")
      html.to_string()
    }
    ThematicBreak => "<hr />\n"
    EmptyLine => ""
  }
}

///|
/// 渲染块级元素数组为 HTML
pub fn render_blocks(blocks : Array[BlockElement]) -> String {
  let html = StringBuilder::new()
  for block in blocks {
    html.write_string(render_block(block))
  }
  html.to_string()
}

///|
/// 解析表格行（以 | 分隔的单元格）
fn parse_table_row(line : String) -> Array[String] {
  let cells = Array::new()
  let trimmed = line.trim()
  // 去掉开头和结尾的 |
  let mut content = trimmed
  if content.has_prefix("|") {
    content = content.sub(start=1).to_owned()
  }
  if content.has_suffix("|") {
    content = content.sub(end=content.length() - 1).to_owned()
  }
  // 按 | 分割
  let parts = content.split("|")
  for part in parts {
    cells.push(part.trim().to_owned())
  }
  cells
}

///|
/// 解析 Markdown 文本为 AST
pub fn parse_markdown(text : String) -> Document {
  let lines = text.split("\n").collect()
  let blocks = Array::new()
  let i = Ref(0)

  while i.val < lines.length() {
    let line = lines[i.val]
    let trimmed = line.trim()

    if trimmed.length() == 0 {
      blocks.push(EmptyLine)
      i.val = i.val + 1
      continue
    }

    // 标题
    if trimmed.has_prefix("# ") {
      let content = trimmed.sub(start=2).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(1, elements))
      i.val = i.val + 1
      continue
    }
    if trimmed.has_prefix("## ") {
      let content = trimmed.sub(start=3).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(2, elements))
      i.val = i.val + 1
      continue
    }
    if trimmed.has_prefix("### ") {
      let content = trimmed.sub(start=4).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(3, elements))
      i.val = i.val + 1
      continue
    }
    if trimmed.has_prefix("#### ") {
      let content = trimmed.sub(start=5).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(4, elements))
      i.val = i.val + 1
      continue
    }
    if trimmed.has_prefix("##### ") {
      let content = trimmed.sub(start=6).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(5, elements))
      i.val = i.val + 1
      continue
    }
    if trimmed.has_prefix("###### ") {
      let content = trimmed.sub(start=7).to_owned()
      let elements = parse_inline(content)
      blocks.push(Heading(6, elements))
      i.val = i.val + 1
      continue
    }

    // 代码块
    if trimmed.has_prefix("```") {
      let language = trimmed.sub(start=3).to_owned().trim().to_owned()
      let code_lines = Array::new()
      i.val = i.val + 1
      while i.val < lines.length() && !lines[i.val].trim().has_prefix("```") {
        code_lines.push(lines[i.val])
        i.val = i.val + 1
      }
      if i.val < lines.length() {
        i.val = i.val + 1
      }
      let code = code_lines.join("\n")
      blocks.push(CodeBlock(language, code))
      continue
    }

    // 引用块
    if trimmed.has_prefix("> ") {
      let quote_lines = Array::new()
      while i.val < lines.length() && lines[i.val].trim().has_prefix("> ") {
        let content = lines[i.val].trim().sub(start=2).to_owned()
        quote_lines.push(content)
        i.val = i.val + 1
      }
      let quote_text = quote_lines.join("\n")
      let inner_doc = parse_markdown(quote_text)
      blocks.push(Blockquote(inner_doc.blocks))
      continue
    }

    // 水平分割线
    if trimmed == "---" || trimmed == "***" || trimmed == "___" {
      blocks.push(ThematicBreak)
      i.val = i.val + 1
      continue
    }

    // 无序列表
    if trimmed.has_prefix("- ") || trimmed.has_prefix("* ") {
      let items = Array::new()
      while i.val < lines.length() {
        let current = lines[i.val].trim()
        if current.has_prefix("- ") || current.has_prefix("* ") {
          let content = current.sub(start=2).to_owned()
          let elements = parse_inline(content)
          items.push(ListItem::{ blocks: [Paragraph(elements)] })
          i.val = i.val + 1
        } else {
          break
        }
      }
      blocks.push(UnorderedList(items))
      continue
    }

    // 有序列表
    if trimmed.length() >= 2 && trimmed[0] >= '0' && trimmed[0] <= '9' && trimmed[1] == '.' {
      let items = Array::new()
      while i.val < lines.length() {
        let current = lines[i.val].trim()
        if current.length() >= 2 && current[0] >= '0' && current[0] <= '9' && current[1] == '.' {
          let content = current.sub(start=2).to_owned()
          let elements = parse_inline(content)
          items.push(ListItem::{ blocks: [Paragraph(elements)] })
          i.val = i.val + 1
        } else {
          break
        }
      }
      blocks.push(OrderedList(items))
      continue
    }

    // 表格
    if trimmed.has_prefix("|") && i.val + 1 < lines.length() {
      let next_line = lines[i.val + 1].trim()
      if next_line.has_prefix("|") && (next_line.find("---") is Some(_) || next_line.find("===") is Some(_)) {
        // 解析表头
        let header_cells = parse_table_row(trimmed.to_owned())
        let headers = Array::new()
        for cell in header_cells {
          headers.push(parse_inline(cell))
        }
        i.val = i.val + 2 // 跳过表头和分隔行
        // 解析表格行
        let rows = Array::new()
        while i.val < lines.length() {
          let row_line = lines[i.val].trim()
          if row_line.has_prefix("|") {
            let row_cells = parse_table_row(row_line.to_owned())
            let row = Array::new()
            for cell in row_cells {
              row.push(parse_inline(cell))
            }
            rows.push(row)
            i.val = i.val + 1
          } else {
            break
          }
        }
        blocks.push(Table(headers, rows))
        continue
      }
    }

    // 普通段落
    let para_lines = Array::new()
    while i.val < lines.length() {
      let current = lines[i.val].trim()
      if current.length() == 0 {
        break
      }
      if current.has_prefix("#") || current.has_prefix("```") || current.has_prefix("> ") {
        break
      }
      if current == "---" || current == "***" || current == "___" {
        break
      }
      if (current.has_prefix("- ") || current.has_prefix("* ")) && para_lines.length() > 0 {
        break
      }
      if current.length() >= 2 && current[0] >= '0' && current[0] <= '9' && current[1] == '.' && para_lines.length() > 0 {
        break
      }
      para_lines.push(current)
      i.val = i.val + 1
    }
    if para_lines.length() > 0 {
      let para_text = para_lines.join(" ")
      let elements = parse_inline(para_text)
      blocks.push(Paragraph(elements))
    }
  }

  Document::{ blocks: blocks }
}

///|
/// 将 Markdown 转换为 HTML
pub fn markdown_to_html(text : String) -> String {
  let doc = parse_markdown(text)
  render_blocks(doc.blocks)
}

///|
/// Markdown 渲染器选项
pub struct MarkdownOptions {
  wrap_in_html : Bool
  title : String
  css : String
}

pub fn MarkdownOptions::default() -> MarkdownOptions {
  MarkdownOptions::{
    wrap_in_html: false,
    title: "Markdown Document",
    css: "body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }",
  }
}

///|
/// 将 Markdown 渲染为 HTML
pub fn md_render(text : String) -> String {
  markdown_to_html(text)
}

///|
/// 将 Markdown 渲染为 HTML（带选项）
pub fn md_render_with_options(text : String, options : MarkdownOptions) -> String {
  let html = markdown_to_html(text)
  if options.wrap_in_html {
    "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<title>" + options.title + "</title>\n<style>" + options.css + "</style>\n</head>\n<body>\n" + html + "</body>\n</html>"
  } else {
    html
  }
}

///|
/// 处理 md 命令的函数
pub async fn run_md(matches : @argparse.Matches) -> Unit {
  let full = get_flag(matches.flags, "full")
  let title = get_option(matches.values, "title")
  let file = get_positional(matches.values, "file", "")

  let text = if file.length() > 0 {
    let data = @fs.read_file(file)
    data.text()
  } else {
    let data = @stdio.stdin.read_all()
    data.text()
  }

  let options = if full {
    MarkdownOptions::{
      wrap_in_html: true,
      title: if title.length() > 0 { title } else { "Markdown Document" },
      css: "body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }\npre { background: #f5f5f5; padding: 10px; border-radius: 4px; overflow-x: auto; }\ncode { background: #f5f5f5; padding: 2px 4px; border-radius: 2px; }\nblockquote { border-left: 4px solid #ddd; margin: 0; padding-left: 16px; color: #666; }\n",
    }
  } else {
    MarkdownOptions::default()
  }

  let html = md_render_with_options(text, options)
  @stdio.stdout.write(html)
}
