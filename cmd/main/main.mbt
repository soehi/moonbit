// main.mbt — moonsh CLI 入口
// 使用 argparse 子命令分发到各命令

///|
async fn main {
  let cmd = @argparse.Command(
    "moonsh",
    about="现代化 Shell 命令行工具集",
    version=@moonsh.moonsh_version,
    subcommands=[
      // ls
      @argparse.Command(
        "ls",
        about="列出目录内容（类似 exa/eza）",
        flags=[
          FlagArg(
            "all",
            short='a',
            long="all",
            about="显示所有文件（包括隐藏文件）",
          ),
          FlagArg(
            "long",
            short='l',
            long="long",
            about="长格式输出（权限、大小、日期）",
          ),
          FlagArg("tree", short='t', long="tree", about="树形显示"),
          FlagArg("color", short='c', long="color", about="启用颜色输出"),
        ],
        positionals=[
          PositionArg(
            "path",
            about="目录路径（默认当前目录）",
            num_args=ValueRange(lower=0),
          ),
        ],
      ),
      // cat
      @argparse.Command(
        "cat",
        about="查看文件内容（类似 bat）",
        flags=[
          FlagArg("number", short='n', long="number", about="显示行号"),
          FlagArg("color", short='c', long="color", about="语法高亮"),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // find
      @argparse.Command(
        "find",
        about="搜索文件（类似 fd）",
        flags=[
          FlagArg(
            "type",
            long="type",
            about="文件类型过滤（f=文件, d=目录, l=链接）",
          ),
          FlagArg(
            "hidden",
            short='H',
            long="hidden",
            about="包含隐藏文件",
          ),
        ],
        options=[
          OptionArg(
            "name",
            short='n',
            long="name",
            about="按 glob 模式匹配文件名",
          ),
          OptionArg(
            "maxdepth",
            short='d',
            long="max-depth",
            about="最大搜索深度",
          ),
        ],
        positionals=[
          PositionArg(
            "path",
            about="搜索路径（默认当前目录）",
            num_args=ValueRange(lower=0),
          ),
          PositionArg(
            "pattern",
            about="搜索模式",
            num_args=ValueRange(lower=0),
          ),
        ],
      ),
      // grep
      @argparse.Command(
        "grep",
        about="文本搜索（类似 ripgrep）",
        flags=[
          FlagArg(
            "ignore_case",
            short='i',
            long="ignore-case",
            about="忽略大小写",
          ),
          FlagArg(
            "line_number",
            short='n',
            long="line-number",
            about="显示行号",
          ),
          FlagArg("invert", short='v', long="invert", about="反向匹配"),
        ],
        options=[
          OptionArg(
            "context",
            short='C',
            long="context",
            about="上下文行数",
          ),
        ],
        positionals=[
          PositionArg("pattern", about="正则表达式"),
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // wc
      @argparse.Command(
        "wc",
        about="统计行/单词/字符数",
        flags=[
          FlagArg("lines", short='l', long="lines", about="只显示行数"),
          FlagArg("words", short='w', long="words", about="只显示单词数"),
          FlagArg("chars", short='c', long="chars", about="只显示字符数"),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // head
      @argparse.Command(
        "head",
        about="显示文件开头",
        options=[
          OptionArg(
            "lines",
            short='n',
            long="lines",
            about="行数（默认10）",
            default_values=["10"],
          ),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // tail
      @argparse.Command(
        "tail",
        about="显示文件末尾",
        options=[
          OptionArg(
            "lines",
            short='n',
            long="lines",
            about="行数（默认10）",
            default_values=["10"],
          ),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // stat
      @argparse.Command("stat", about="显示文件信息", positionals=[
        PositionArg("file", about="文件路径"),
      ]),
      // sort
      @argparse.Command(
        "sort",
        about="排序文本行",
        flags=[
          FlagArg("numeric", short='n', long="numeric", about="数值排序"),
          FlagArg("natural", long="natural", about="自然排序"),
          FlagArg("version", long="version", about="版本号排序"),
          FlagArg("reverse", short='r', long="reverse", about="逆序"),
          FlagArg("unique", short='u', long="unique", about="去重"),
          FlagArg(
            "ignore_case",
            short='f',
            long="ignore-case",
            about="忽略大小写",
          ),
          FlagArg(
            "ignore_blanks",
            short='b',
            long="ignore-blanks",
            about="忽略前导空白",
          ),
        ],
        options=[
          OptionArg("key", short='k', long="key", about="按字段排序"),
          OptionArg(
            "separator",
            short='t',
            long="separator",
            about="字段分隔符",
          ),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // uniq
      @argparse.Command(
        "uniq",
        about="去除相邻重复行",
        flags=[
          FlagArg(
            "repeated",
            short='d',
            long="repeated",
            about="只显示重复行",
          ),
          FlagArg(
            "unique",
            short='u',
            long="unique",
            about="只显示唯一行",
          ),
          FlagArg("count", short='c', long="count", about="显示计数"),
          FlagArg(
            "ignore_case",
            short='i',
            long="ignore-case",
            about="忽略大小写",
          ),
        ],
        options=[
          OptionArg(
            "skip_fields",
            short='f',
            long="skip-fields",
            about="跳过前N个字段",
          ),
          OptionArg(
            "skip_chars",
            short='s',
            long="skip-chars",
            about="跳过前N个字符",
          ),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // cut
      @argparse.Command(
        "cut",
        about="提取字段或字符",
        options=[
          OptionArg(
            "delimiter",
            short='d',
            long="delimiter",
            about="字段分隔符",
          ),
          OptionArg("fields", short='f', long="fields", about="提取字段"),
          OptionArg(
            "characters",
            short='c',
            long="characters",
            about="提取字符",
          ),
          OptionArg("bytes", short='b', long="bytes", about="提取字节"),
        ],
        positionals=[
          PositionArg(
            "file",
            about="文件路径",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
      // tr
      @argparse.Command(
        "tr",
        about="字符转换/删除/压缩",
        flags=[
          FlagArg("delete", short='d', long="delete", about="删除字符"),
          FlagArg("squeeze", short='s', long="squeeze", about="压缩重复"),
          FlagArg(
            "complement",
            short='c',
            long="complement",
            about="反转字符集",
          ),
          FlagArg("truncate", short='t', long="truncate", about="截断模式"),
        ],
        positionals=[
          PositionArg("set1", about="源字符集"),
          PositionArg(
            "set2",
            about="目标字符集",
            num_args=ValueRange(lower=0),
          ),
        ],
      ),
      // diff
      @argparse.Command(
        "diff",
        about="比较文件差异",
        flags=[FlagArg("color", short='c', long="color", about="彩色输出")],
        positionals=[
          PositionArg("file1", about="旧文件"),
          PositionArg("file2", about="新文件"),
        ],
      ),
      // md - Markdown 渲染器
      @argparse.Command(
        "md",
        about="Markdown 渲染为 HTML",
        flags=[
          FlagArg("full", short='f', long="full", about="生成完整 HTML 文档"),
        ],
        options=[
          OptionArg("title", short='t', long="title", about="HTML 文档标题"),
        ],
        positionals=[
          PositionArg(
            "file",
            about="Markdown 文件路径（不指定则从 stdin 读取）",
            num_args=ValueRange(lower=0),
            allow_hyphen_values=true,
          ),
        ],
      ),
    ],
    subcommand_required=true,
    arg_required_else_help=true,
  )
  let matches = cmd.parse()
  match matches.subcommand {
    Some((name, sub_matches)) =>
      match name {
        "ls" => @moonsh.run_ls(sub_matches)
        "cat" => @moonsh.run_cat(sub_matches)
        "find" => @moonsh.run_find(sub_matches)
        "grep" => @moonsh.run_grep(sub_matches)
        "wc" => @moonsh.run_wc(sub_matches)
        "head" => @moonsh.run_head(sub_matches)
        "tail" => @moonsh.run_tail(sub_matches)
        "stat" => @moonsh.run_stat(sub_matches)
        "sort" => @moonsh.run_sort(sub_matches)
        "uniq" => @moonsh.run_uniq(sub_matches)
        "cut" => @moonsh.run_cut(sub_matches)
        "tr" => @moonsh.run_tr(sub_matches)
        "diff" => @moonsh.run_diff(sub_matches)
        "md" => @moonsh.run_md(sub_matches)
        _ => @stdio.stdout.write("Unknown command: \{name}\n")
      }
    None => @stdio.stdout.write("Usage: moonsh <command> [options]\n")
  }
}
