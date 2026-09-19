///|
/// In-memory connection used to exercise the request pipeline without a
/// real socket (works on every build target).
struct MemSock {
  in_bytes : Bytes
  in_pos : @ref.Ref[Int]
  out : Buffer
}

///|
fn MemSock::of(data : Bytes) -> MemSock {
  { in_bytes: data, in_pos: @ref.Ref(0), out: Buffer() }
}

///|
impl Connection for MemSock with fn read(self, buf) {
  let pos = self.in_pos.val
  let avail = self.in_bytes.length() - pos
  if avail <= 0 {
    return 0
  }
  let take = if buf.length() < avail { buf.length() } else { avail }
  buf.blit_from_bytesview(0, self.in_bytes[pos:pos + take])
  self.in_pos.val = pos + take
  take
}

///|
impl Connection for MemSock with fn write_all(self, data) {
  self.out.write_bytes(data)
}

///|
impl Connection for MemSock with fn close(_self) {
  ()
}

///|
test "read request over in-memory connection" {
  let sock = MemSock::of(b"GET /index.html HTTP/1.0\r\nHost: x\r\n\r\n")
  let reader = ConnReader::new(sock, buf_size=8)
  let req = reader.read_request()
  inspect(req is None, content="false")
  let req = req.unwrap()
  inspect(req.path, content="/index.html")
  inspect(req.header("host") == Some("x"), content="true")
}

///|
test "body read across buffer refills" {
  let sock = MemSock::of(
    b"POST /cgi-bin/color.cgi HTTP/1.0\r\nContent-Length: 11\r\n\r\nhello=world",
  )
  let reader = ConnReader::new(sock, buf_size=4)
  let req = reader.read_request().unwrap()
  inspect(@utf8.decode_lossy(req.body.view()), content="hello=world")
}

///|
test "eof without request yields none" {
  let sock = MemSock::of(b"")
  let reader = ConnReader::new(sock)
  inspect(reader.read_request() is None, content="true")
}

///|
test "write and read back wire bytes" {
  let sock = MemSock::of(b"GET / HTTP/1.0\r\n\r\n")
  let reader = ConnReader::new(sock)
  let _ = reader.read_request()
  Connection::write_all(
    sock,
    @http.Response::create(200, "text/plain", b"ok").to_wire(),
  )
  inspect(
    @utf8.decode_lossy(sock.out.to_bytes().view()).has_prefix("HTTP/1.0 200 OK"),
    content="true",
  )
}
