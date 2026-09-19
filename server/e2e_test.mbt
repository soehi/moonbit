// End-to-end pipeline test: raw request bytes in, wire-format response
// out — the same path handle_one drives for a real TCP connection.

///|
fn roundtrip(app : App, raw : Bytes) -> String {
  let sock = MemSock::of(raw)
  let reader = ConnReader::new(sock, buf_size=7)
  let resp = match reader.read_request() {
    Some(req) => app.serve(req)
    None => @http.Response::error(400, "Bad Request")
  }
  Connection::write_all(sock, resp.to_wire())
  @utf8.decode_lossy(sock.out.to_bytes().view())
}

///|
test "end to end serves the index page" {
  let app = App::new(MemoryLogger::new())
  let out = roundtrip(app, b"GET / HTTP/1.0\r\n\r\n")
  inspect(out.has_prefix("HTTP/1.0 200 OK"), content="true")
  inspect(out.contains("It works!"), content="true")
}

///|
test "end to end runs env cgi with a raw query string" {
  let app = App::new(MemoryLogger::new())
  let out = roundtrip(
    app, b"GET /cgi-bin/env.cgi?name=%E5%91%A8 HTTP/1.0\r\nUser-Agent: e2e/1.0\r\n\r\n",
  )
  inspect(out.has_prefix("HTTP/1.0 200 OK"), content="true")
  inspect(out.contains("QUERY_STRING</td><td>name=%E5%91%A8"), content="true")
  inspect(out.contains("HTTP_USER_AGENT</td><td>e2e/1.0"), content="true")
}

///|
test "end to end runs color cgi with a decoded color" {
  let app = App::new(MemoryLogger::new())
  let out = roundtrip(
    app, b"GET /cgi-bin/color.cgi?color=%2300ff00 HTTP/1.0\r\n\r\n",
  )
  inspect(out.has_prefix("HTTP/1.0 200 OK"), content="true")
  inspect(out.contains("color = #00ff00"), content="true")
}

///|
test "end to end reports 404 and 501" {
  let app = App::new(MemoryLogger::new())
  inspect(
    roundtrip(app, b"GET /gone HTTP/1.0\r\n\r\n").has_prefix("HTTP/1.0 404"),
    content="true",
  )
  inspect(
    roundtrip(app, b"DELETE / HTTP/1.0\r\n\r\n").has_prefix("HTTP/1.0 501"),
    content="true",
  )
}

///|
test "end to end answers head without a body" {
  let app = App::new(MemoryLogger::new())
  let out = roundtrip(app, b"HEAD / HTTP/1.0\r\n\r\n")
  inspect(out.has_prefix("HTTP/1.0 200 OK"), content="true")
  inspect(out.contains("Content-Length: "), content="true")
  inspect(out.has_suffix("\r\n\r\n"), content="true")
}

///|
test "end to end answers garbage with 400" {
  let app = App::new(MemoryLogger::new())
  let sock = MemSock::of(b"total nonsense\r\n\r\n")
  let reader = ConnReader::new(sock)
  let resp = match reader.read_request() {
    Some(req) => app.serve(req)
    None => @http.Response::error(400, "Bad Request")
  }
  inspect(resp.status, content="400")
}
