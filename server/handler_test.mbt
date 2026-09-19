///|
test "static index served" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request("GET / HTTP/1.0\r\n\r\n").unwrap()
  let resp = app.serve(req)
  inspect(resp.status, content="200")
  inspect(resp.headers.get("Content-Type") == Some("text/html"), content="true")
  inspect(
    @utf8.decode_lossy(resp.body.view()).contains("It works!"),
    content="true",
  )
}

///|
test "missing file returns 404" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request("GET /nope.html HTTP/1.0\r\n\r\n").unwrap()
  inspect(app.serve(req).status, content="404")
}

///|
test "unimplemented method returns 501" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request("DELETE / HTTP/1.0\r\n\r\n").unwrap()
  inspect(app.serve(req).status, content="501")
}

///|
test "head strips body but keeps content-length" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request("HEAD / HTTP/1.0\r\n\r\n").unwrap()
  let resp = app.serve(req)
  inspect(resp.body.length(), content="0")
  inspect(resp.headers.get("Content-Length") is None, content="false")
}

///|
test "env.cgi renders through the ssi engine" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request(
    "GET /cgi-bin/env.cgi?name=Jim HTTP/1.0\r\nUser-Agent: Probe/1.0\r\n\r\n",
  ).unwrap()
  let resp = app.serve(req)
  inspect(resp.status, content="200")
  let html = @utf8.decode_lossy(resp.body.view())
  inspect(html.contains("QUERY_STRING</td><td>name=Jim"), content="true")
  inspect(html.contains("REQUEST_METHOD</td><td>GET"), content="true")
  inspect(html.contains("HTTP_USER_AGENT</td><td>Probe/1.0"), content="true")
}

///|
test "color.cgi echoes a sanitized color" {
  let app = App::new(MemoryLogger::new())
  let req = @http.parse_request(
    "GET /cgi-bin/color.cgi?color=%2300ff00 HTTP/1.0\r\n\r\n",
  ).unwrap()
  let resp = app.serve(req)
  inspect(resp.status, content="200")
  inspect(
    @utf8.decode_lossy(resp.body.view()).contains("color = #00ff00"),
    content="true",
  )
  let evil = @http.parse_request(
    "GET /cgi-bin/color.cgi?color=<script> HTTP/1.0\r\n\r\n",
  ).unwrap()
  let html = @utf8.decode_lossy(app.serve(evil).body.view())
  inspect(html.contains("<script>"), content="false")
}

///|
test "requests are logged" {
  let logger = MemoryLogger::new()
  let app = App::new(logger)
  let _ = app.serve(@http.parse_request("GET / HTTP/1.0\r\n\r\n").unwrap())
  let _ = app.serve(@http.parse_request("GET /gone HTTP/1.0\r\n\r\n").unwrap())
  let lines = logger.snapshot()
  inspect(lines.length(), content="2")
  inspect(lines[0], content="GET / -> 200")
  inspect(lines[1], content="GET /gone -> 404")
}
