// The HTTP application: routes requests over the in-memory document
// root, dispatches CGI endpoints and reports every request to a logger.

///|
/// Where request handling is reported to.
pub(open) trait Logger {
  fn log(Self, String) -> Unit
}

///|
/// Logger that keeps every line in memory (used by tests and available
/// for introspection).
pub struct MemoryLogger {
  lines : Array[String]
}

///|
pub fn MemoryLogger::new() -> MemoryLogger {
  { lines: [] }
}

///|
/// Snapshot of the recorded log lines.
pub fn MemoryLogger::snapshot(self : MemoryLogger) -> Array[String] {
  self.lines.copy()
}

///|
pub impl Logger for MemoryLogger with fn log(self, line) {
  self.lines.push(line)
}

///|
/// The tiny-httpd application.
pub struct App {
  vfs : Vfs
  cgi : Map[String, &CgiProgram]
  logger : &Logger
}

///|
/// Create the app with the bundled demo document root and CGI endpoints.
pub fn App::new(logger : &Logger) -> App {
  let app = { vfs: Vfs::new(), cgi: Map([]), logger }
  app.register_defaults()
  app
}

///|
/// Handle one request: dispatch, apply HEAD semantics, then report to
/// the logger.
pub fn App::serve(self : App, req : @http.Request) -> @http.Response {
  let resp = self.route(normalize_path(req.path), req)
  self.logger.log(
    req.verb.to_string() + " " + req.path + " -> " + resp.status.to_string(),
  )
  if req.verb is @http.Head {
    resp.without_body()
  } else {
    resp
  }
}

///|
fn App::route(self : App, path : String, req : @http.Request) -> @http.Response {
  match req.verb {
    @http.Get | @http.Post | @http.Head => ()
    _ => return @http.Response::error(501, "Method Not Implemented")
  }
  match self.cgi.get(path) {
    Some(prog) => return prog.run(req)
    None => ()
  }
  if path.has_suffix(".cgi") {
    match self.vfs.get(path) {
      Some(file) => {
        let html = render_ssi(
          @utf8.decode_lossy(file.bytes.view()),
          cgi_env(req),
        )
        return @http.Response::create(200, "text/html", @utf8.encode(html))
      }
      None => return @http.Response::error(404, "Not Found")
    }
  }
  match self.vfs.get(path) {
    Some(file) => @http.Response::create(200, file.content_type, file.bytes)
    None => @http.Response::error(404, "Not Found")
  }
}

///|
fn App::register_defaults(self : App) -> Unit {
  self.vfs.add_string("/", "text/html", index_html())
  self.vfs.add_string("/styles.css", "text/css", styles_css())
  self.vfs.add_string("/cgi-bin/env.cgi", "text/plain", env_cgi_script())
  self.cgi["/cgi-bin/color.cgi"] = cgi_fn(color_cgi)
}
