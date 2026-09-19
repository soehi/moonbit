// tiny-httpd command line entry point: argument handling, banner and
// the blocking accept loop.

///|
fn main {
  let args = @env.args()
  let mut port = 8080
  let mut i = 1
  while i < args.length() {
    let a = args[i]
    if (a == "-p" || a == "--port") && i + 1 < args.length() {
      let parsed = @string.parse_int(args[i + 1]) catch { _ => -1 }
      if parsed > 0 && parsed < 65536 {
        port = parsed
        i += 2
      } else {
        println(
          "tiny-httpd: error: port must be 1..65535, got '" + args[i + 1] + "'",
        )
        return
      }
    } else if a == "-h" || a == "--help" {
      print_usage()
      return
    } else if a == "-v" || a == "--version" {
      println(
        "tiny-httpd-moonbit " +
        @tinyhttpd.VERSION +
        " (MoonBit port of tinyhttpd)",
      )
      return
    } else {
      println("tiny-httpd: error: unknown argument '" + a + "'")
      print_usage()
      return
    }
  }
  banner(port)
  let logger : &@server.Logger = @server.MemoryLogger::new()
  let app = @server.App::new(logger)
  match @server.serve_forever(app, port) {
    Some(err) => println("tiny-httpd: error: " + err)
    None => ()
  }
}

///|
fn banner(port : Int) -> Unit {
  println(
    "tiny-httpd-moonbit " +
    @tinyhttpd.VERSION +
    " - MoonBit port of tinyhttpd (GPL)",
  )
  println(
    "listening on http://127.0.0.1:" + port.to_string() + "/ (Ctrl+C to stop)",
  )
  println(
    "try: /  /cgi-bin/env.cgi?name=Jim  /cgi-bin/color.cgi?color=%2300ff00",
  )
}

///|
fn print_usage() -> Unit {
  println(
    "tiny-httpd-moonbit " +
    @tinyhttpd.VERSION +
    " - a tiny HTTP server in pure MoonBit",
  )
  println("")
  println("USAGE: tiny-httpd [OPTIONS]")
  println("")
  println("OPTIONS:")
  println("  -p, --port <PORT>  port to listen on (default 8080)")
  println("  -h, --help         print this help")
  println("  -v, --version      print version")
}
