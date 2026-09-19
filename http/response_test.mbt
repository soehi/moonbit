///|
test "response wire format is deterministic" {
  let r = Response::create(200, "text/html", b"<h1>hi</h1>")
  inspect(
    @utf8.decode_lossy(r.to_wire().view()),
    content="HTTP/1.0 200 OK\r\nConnection: close\r\nContent-Length: 11\r\nContent-Type: text/html\r\nServer: tiny-httpd-moonbit/0.1\r\n\r\n<h1>hi</h1>",
  )
}

///|
test "error page" {
  let r = Response::error(404, "Not Found")
  inspect(r.status, content="404")
  inspect(
    @utf8.decode_lossy(r.body.view()).contains("<h1>404 Not Found</h1>"),
    content="true",
  )
  inspect(
    @utf8.decode_lossy(r.body.view()).contains("<script>"),
    content="false",
  )
}

///|
test "head response keeps content-length" {
  let r = Response::create(200, "text/plain", b"abc").without_body()
  inspect(r.body.length(), content="0")
  inspect(r.headers.get("Content-Length") == Some("3"), content="true")
}

///|
test "escape html" {
  inspect(
    escape_html("<b>&\"'</b>"),
    content="&lt;b&gt;&amp;&quot;&#39;&lt;/b&gt;",
  )
  inspect(escape_html("clean"), content="clean")
}
