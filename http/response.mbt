// HTTP response building and wire serialization, ported in spirit from
// tinyhttpd's headers/error helpers.

///|
/// Reason phrases for the status codes tiny-httpd emits.
pub fn reason_phrase(status : Int) -> String {
  match status {
    200 => "OK"
    201 => "Created"
    204 => "No Content"
    301 => "Moved Permanently"
    302 => "Found"
    304 => "Not Modified"
    400 => "Bad Request"
    403 => "Forbidden"
    404 => "Not Found"
    405 => "Method Not Allowed"
    500 => "Internal Server Error"
    501 => "Not Implemented"
    _ => "Unknown"
  }
}

///|
/// An HTTP response. Headers live in a sorted map so the wire format is
/// deterministic across runs and platforms.
pub struct Response {
  status : Int
  headers : @sorted_map.SortedMap[String, String]
  body : Bytes
}

///|
/// Build a full response with the standard tiny-httpd headers set.
pub fn Response::create(status : Int, content_type : String, body : Bytes) -> Response {
  let resp = { status, headers: @sorted_map.SortedMap([]), body }
  resp.headers.set("Content-Type", content_type)
  resp.headers.set("Content-Length", body.length().to_string())
  resp.headers.set("Connection", "close")
  resp.headers.set("Server", "tiny-httpd-moonbit/0.1")
  resp
}

///|
/// Byte-wise comparison of two strings (header names are ASCII; the
/// default Compare on String is not guaranteed to be lexicographic on
/// all backends, so header ordering is made explicit here).
fn compare_bytes(a : String, b : String) -> Int {
  let ba = @utf8.encode(a)
  let bb = @utf8.encode(b)
  let n = if ba.length() < bb.length() { ba.length() } else { bb.length() }
  for i = 0; i < n; i = i + 1 {
    let d = ba[i].to_int() - bb[i].to_int()
    if d != 0 {
      return d
    }
  }
  ba.length() - bb.length()
}

///|
/// Serialize the response to HTTP/1.0 wire format. Headers are emitted in
/// alphabetical order so output is deterministic across platforms.
pub fn Response::to_wire(self : Response) -> Bytes {
  let head = StringBuilder(size_hint=256)
  head.write_string("HTTP/1.0 ")
  head.write_string(self.status.to_string())
  head.write_string(" ")
  head.write_string(reason_phrase(self.status))
  head.write_string("\r\n")
  let names : Array[String] = []
  for name, _ in self.headers.iter2() {
    names.push(name)
  }
  names.sort_by(compare_bytes)
  for name in names {
    match self.headers.get(name) {
      Some(value) => {
        head.write_string(name)
        head.write_string(": ")
        head.write_string(value)
        head.write_string("\r\n")
      }
      None => ()
    }
  }
  head.write_string("\r\n")
  Bytes::add(@utf8.encode(head.to_string()), self.body)
}

///|
/// Build an HTML error page in the style of the original tinyhttpd.
pub fn Response::error(status : Int, message : String) -> Response {
  let reason = reason_phrase(status)
  let html = "<html>\r\n<head><title>" + status.to_string() + " " + reason + "</title></head>\r\n<body>\r\n<h1>" + status.to_string() + " " + reason + "</h1>\r\n<p>" + escape_html(message) + "</p>\r\n<hr>tiny-httpd-moonbit/0.1\r\n</body>\r\n</html>\r\n"
  Response::create(status, "text/html", @utf8.encode(html))
}

///|
/// A HEAD-style response: body removed, Content-Length kept.
pub fn Response::without_body(self : Response) -> Response {
  { ..self, body: Bytes::make(0, b'\x00') }
}

///|
/// Escape HTML-significant characters (&, <, >, ", ') for safe embedding
/// in generated pages (the original tinyhttpd echoed CGI output verbatim;
/// this port refuses to propagate XSS).
pub fn escape_html(s : String) -> String {
  let out = StringBuilder(size_hint=s.length())
  for c in s.iter() {
    if c == '&' {
      out.write_string("&amp;")
    } else if c == '<' {
      out.write_string("&lt;")
    } else if c == '>' {
      out.write_string("&gt;")
    } else if c == '"' {
      out.write_string("&quot;")
    } else if c == '\'' {
      out.write_string("&#39;")
    } else {
      out.write_char(c)
    }
  }
  out.to_string()
}
