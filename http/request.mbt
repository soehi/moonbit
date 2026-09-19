// HTTP request parsing, ported in spirit from tinyhttpd's accept_request:
// request line, headers and body, with CGI-style query decoding.

///|
/// HTTP request methods understood by tiny-httpd.
pub enum HttpMethod {
  Get
  Post
  Head
  Put
  Delete
  Options
} derive(Eq)

///|
pub fn HttpMethod::to_string(self : HttpMethod) -> String {
  match self {
    Get => "GET"
    Post => "POST"
    Head => "HEAD"
    Put => "PUT"
    Delete => "DELETE"
    Options => "OPTIONS"
  }
}

///|
/// A parsed HTTP/1.x request message.
pub struct Request {
  verb : HttpMethod
  path : String
  raw_query : String
  query : Map[String, String]
  version : String
  headers : Map[String, String]
  body : Bytes
}

///|
/// Header value by case-insensitive name.
pub fn Request::header(self : Request, name : String) -> String? {
  self.headers.get(name.to_lower())
}

///|
/// Decoded query parameter value.
pub fn Request::param(self : Request, name : String) -> String? {
  self.query.get(name)
}

///|
/// Replace the body of a parsed request (used by streaming readers that
/// read the body after the headers).
pub fn Request::with_body(self : Request, body : Bytes) -> Request {
  { ..self, body }
}

///|
/// Parse a complete HTTP request (request line, headers, body). Returns
/// None for malformed input. Tolerates LF-only line endings.
pub fn parse_request(raw : String) -> Request? {
  let len = raw.length()
  let (head, body) = match raw.find("\r\n\r\n") {
    Some(i) => (raw[0:i].to_owned(), @utf8.encode(raw[i + 4:len]))
    None =>
      match raw.find("\n\n") {
        Some(i) => (raw[0:i].to_owned(), @utf8.encode(raw[i + 2:len]))
        None => (raw, Bytes::make(0, b'\x00'))
      }
  }
  let sep = if head.contains("\r\n") { "\r\n" } else { "\n" }
  let mut request_line : String? = None
  let headers : Map[String, String] = Map([])
  let mut first = true
  for line in head.split(sep) {
    if first {
      first = false
      request_line = Some(line.to_owned())
    } else {
      parse_header_line(line.to_owned(), headers)
    }
  }
  let line = match request_line {
    Some(l) => l
    None => return None
  }
  match parse_request_line(line) {
    Some((m, path, raw_query, version)) =>
      Some({
        verb: m,
        path,
        raw_query,
        query: parse_query(raw_query),
        version,
        headers,
        body,
      })
    None => None
  }
}

///|
/// Parse "GET /path?query HTTP/1.0" into its four parts.
fn parse_request_line(line : String) -> (HttpMethod, String, String, String)? {
  let parts : Array[String] = []
  for p in line.split(" ") {
    let p = p.to_owned()
    if p != "" {
      parts.push(p)
    }
  }
  if parts.length() != 3 {
    return None
  }
  let m = match parts[0].to_upper() {
    "GET" => Get
    "POST" => Post
    "HEAD" => Head
    "PUT" => Put
    "DELETE" => Delete
    "OPTIONS" => Options
    _ => return None
  }
  let target = parts[1]
  let (path, raw_query) = match target.split_once("?") {
    Some((p, q)) => (p.to_owned(), q.to_owned())
    None => (target, "")
  }
  if !path.has_prefix("/") {
    return None
  }
  Some((m, path, raw_query, parts[2]))
}

///|
/// Parse a single "Name: value" header line; header names are
/// lower-cased for case-insensitive lookup.
fn parse_header_line(line : String, headers : Map[String, String]) -> Unit {
  match line.split_once(":") {
    Some((name, value)) => {
      let name = name.to_owned()
      if name != "" && !name.contains(" ") {
        headers[name.to_lower()] = trim_ascii(value.to_owned())
      }
    }
    None => ()
  }
}

///|
fn is_space_char(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r' || c == '\n'
}

///|
/// Trim ASCII whitespace from both ends.
fn trim_ascii(s : String) -> String {
  let chars : Array[Char] = []
  for c in s.iter() {
    chars.push(c)
  }
  let mut lo = 0
  let mut hi = chars.length() - 1
  while lo <= hi && is_space_char(chars[lo]) {
    lo += 1
  }
  while hi >= lo && is_space_char(chars[hi]) {
    hi -= 1
  }
  let out = StringBuilder(size_hint=chars.length())
  for i = lo; i <= hi; i = i + 1 {
    out.write_char(chars[i])
  }
  out.to_string()
}
