// TCP front-end shared by all backends: the accept loop of the original
// tinyhttpd (one connection at a time), expressed over the Connection
// abstraction. The raw primitives come from ffi_tcp_native.mbt on the
// native backend and ffi_tcp_stub.mbt elsewhere.

///|
/// A client connection backed by a native socket handle.
pub struct TcpConn {
  sock : Int
}

///|
pub impl Connection for TcpConn with fn read(self, buf) {
  if buf.length() == 0 {
    0
  } else {
    tinyhttpd_read(self.sock, buf, buf.length())
  }
}

///|
pub impl Connection for TcpConn with fn write_all(self, data) {
  let fa = data.to_fixedarray()
  let n = fa.length()
  let mut off = 0
  while off < n {
    let sent = tinyhttpd_write(self.sock, fa, off, n - off)
    if sent <= 0 {
      return
    }
    off += sent
  }
}

///|
pub impl Connection for TcpConn with fn close(self) {
  tinyhttpd_close(self.sock)
}

///|
/// Bind and listen on all interfaces. Returns the listen handle, or -1
/// when the port could not be bound.
pub fn tcp_listen(port : Int) -> Int {
  tinyhttpd_socket_open(port)
}

///|
/// Block until one client connects. Returns None when the listener
/// failed (e.g. interrupted accept).
pub fn tcp_accept(listen_sock : Int) -> TcpConn? {
  let sock = tinyhttpd_accept(listen_sock)
  if sock < 0 {
    None
  } else {
    let conn : TcpConn = { sock, }
    Some(conn)
  }
}

///|
/// Serve HTTP forever on `port`: accept one connection at a time (like
/// the original tinyhttpd), read one request, write one response, close.
/// Returns an error message only when the port could not be bound;
/// otherwise it never returns.
pub fn serve_forever(app : App, port : Int) -> String? {
  let lsock = tcp_listen(port)
  if lsock < 0 {
    return Some("cannot bind port " + port.to_string())
  }
  let running = true
  while running {
    match tcp_accept(lsock) {
      Some(conn) => handle_one(conn, app)
      None => ()
    }
  }
  None
}

///|
fn handle_one(conn : &Connection, app : App) -> Unit {
  let reader = ConnReader::new(conn)
  let resp = match reader.read_request() {
    Some(req) => app.serve(req)
    None => @http.Response::error(400, "Bad Request")
  }
  conn.write_all(resp.to_wire())
  conn.close()
}
