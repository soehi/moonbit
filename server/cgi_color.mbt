// The color.cgi demo, ported from the original shell script. The
// original interpolated the raw query string into the HTML; this port
// sanitizes the color parameter first.

///|
/// Render an HTML page in the color named by the `color` query
/// parameter (sanitized; defaults to red).
fn color_cgi(req : @http.Request) -> @http.Response {
  let color = match req.param("color") {
    Some(c) => sanitize_color(c)
    None => "#ff0000"
  }
  let page = "<html>\n<head><title>Color: " +
    color +
    "</title></head>\n<body style=\"background-color: " +
    color +
    "\">\n<h1 style=\"color: " +
    color +
    "; font-family: sans-serif\">Hello from a MoonBit CGI program!</h1>\n<p>color = " +
    color +
    "</p>\n</body>\n</html>\n"
  @http.Response::create(200, "text/html", @utf8.encode(page))
}

///|
/// Keep only characters that can appear in a CSS color value, and cap
/// the length, so the parameter can never break out of the attribute.
fn sanitize_color(raw : String) -> String {
  let capped = if raw.length() > 32 { raw[0:32].to_owned() } else { raw }
  let out = StringBuilder(size_hint=capped.length())
  for c in capped.iter() {
    let ok = (c >= '0' && c <= '9') ||
      (c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      c == '#' ||
      c == '%' ||
      c == '(' ||
      c == ')' ||
      c == ',' ||
      c == '.'
    if ok {
      out.write_char(c)
    }
  }
  let s = out.to_string()
  if s == "" {
    "#ff0000"
  } else {
    s
  }
}
