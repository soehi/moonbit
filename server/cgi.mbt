// CGI subsystem. The original tinyhttpd forked a shell per request and
// piped its output back on the socket; this port keeps the CGI contract
// (meta-variables in, full HTTP response out) but executes programs
// inside the server process: compiled MoonBit programs, or server-parsed
// (SSI-style) scripts from the document root.

///|
/// A dynamic endpoint executed like a CGI program: it receives the
/// parsed request and returns the HTTP response (in real CGI this is
/// the child process writing the status line, headers and body to
/// STDOUT).
pub(open) trait CgiProgram {
  fn run(Self, @http.Request) -> @http.Response
}

///|
/// Adapt a plain function into a CgiProgram.
pub fn cgi_fn(f : (@http.Request) -> @http.Response) -> &CgiProgram {
  let obj : FnCgi = { f, }
  obj
}

///|
priv struct FnCgi {
  f : (@http.Request) -> @http.Response
}

///|
impl CgiProgram for FnCgi with fn run(self, req) {
  (self.f)(req)
}

///|
/// Build the CGI 1.1 meta-variables for a request, mirroring what a real
/// CGI server exports to the child process environment.
pub fn cgi_env(
  req : @http.Request,
  server_port? : String = "8080",
) -> Map[String, String] {
  let env : Map[String, String] = Map([])
  env["SERVER_SOFTWARE"] = "tiny-httpd-moonbit/0.1"
  env["SERVER_NAME"] = "tiny-httpd-moonbit"
  env["GATEWAY_INTERFACE"] = "CGI/1.1"
  env["SERVER_PROTOCOL"] = req.version
  env["SERVER_PORT"] = server_port
  env["REQUEST_METHOD"] = req.verb.to_string()
  env["PATH_INFO"] = req.path
  env["QUERY_STRING"] = req.raw_query
  env["CONTENT_LENGTH"] = match req.header("Content-Length") {
    Some(v) => v
    None => ""
  }
  env["CONTENT_TYPE"] = match req.header("Content-Type") {
    Some(v) => v
    None => ""
  }
  env["HTTP_USER_AGENT"] = match req.header("User-Agent") {
    Some(v) => v
    None => "(none)"
  }
  env["HTTP_ACCEPT"] = match req.header("Accept") {
    Some(v) => v
    None => "(none)"
  }
  env
}

///|
fn echo_value(directive : String, env : Map[String, String]) -> String {
  match directive.split_once("var=\"") {
    Some((_, tail)) =>
      match tail.to_owned().split_once("\"") {
        Some((name, _)) =>
          match env.get(name.to_owned()) {
            Some(v) => v
            None => "(none)"
          }
        None => "(none)"
      }
    None => "(none)"
  }
}

///|
/// Render a server-parsed (SSI-style) CGI script: literal text is copied
/// through and `<!--#echo var="NAME" -->` directives are replaced with
/// CGI environment values. Unset variables render as "(none)", echoing
/// what the original env.cgi printed for empty environment entries.
pub fn render_ssi(template : String, env : Map[String, String]) -> String {
  let out = StringBuilder(size_hint=template.length())
  let open = "<!--#echo"
  let mut rest = template
  while true {
    match rest.find(open) {
      Some(idx) => {
        out.write_string(rest[0:idx].to_owned())
        let after = rest[idx + open.length():rest.length()]
        match after.find("-->") {
          Some(end_rel) => {
            out.write_string(echo_value(after[0:end_rel].to_owned(), env))
            rest = after[end_rel + 3:after.length()].to_owned()
          }
          None => {
            out.write_string(rest[idx:rest.length()].to_owned())
            rest = ""
          }
        }
      }
      None => {
        out.write_string(rest)
        rest = ""
      }
    }
    if rest == "" {
      break
    }
  }
  out.to_string()
}
