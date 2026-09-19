// Connection handling: a minimal blocking-socket abstraction plus a
// buffered reader that turns a byte stream into parsed HTTP requests,
// ported in spirit from tinyhttpd's accept_request.

///|
/// One accepted client connection. Implementations provide blocking
/// reads (0 signals EOF) and writes over the underlying transport.
pub(open) trait Connection {
  fn read(Self, FixedArray[Byte]) -> Int
  fn write_all(Self, Bytes) -> Unit
  fn close(Self) -> Unit
}

///|
/// Upper bound for the request head (request line + headers).
const MAX_HEADER_BYTES : Int = 65536

///|
/// Upper bound for a request body (1 MiB).
const MAX_BODY_BYTES : Int = 1048576

///|
/// Upper bound for the number of header lines per request.
const MAX_HEADERS : Int = 100

///|
/// Buffered connection reader that assembles HTTP requests.
pub struct ConnReader {
  conn : &Connection
  buf : FixedArray[Byte]
  mut pos : Int
  mut len : Int
}

///|
pub fn ConnReader::new(
  conn : &Connection,
  buf_size? : Int = 4096,
) -> ConnReader {
  { conn, buf: FixedArray::make(buf_size, b'\x00'), pos: 0, len: 0 }
}

///|
/// Read one LF-terminated line (CR stripped). Returns None only at EOF
/// with nothing buffered, or when the line exceeds the header limit.
fn ConnReader::read_line(self : ConnReader) -> String? {
  let acc = Buffer()
  let reading = true
  while reading {
    if self.pos >= self.len {
      self.pos = 0
      self.len = self.conn.read(self.buf)
      if self.len <= 0 {
        if acc.length() == 0 {
          return None
        }
        return Some(@utf8.decode_lossy(acc.to_bytes().view()))
      }
    }
    let mut found = -1
    for i = self.pos; i < self.len; i = i + 1 {
      if self.buf[i] == b'\n' {
        found = i
        break
      }
    }
    if found >= 0 {
      for i = self.pos; i < found; i = i + 1 {
        acc.write_byte(self.buf[i])
      }
      self.pos = found + 1
      let line = @utf8.decode_lossy(acc.to_bytes().view())
      if line.has_suffix("\r") {
        return Some(line[0:line.length() - 1].to_owned())
      }
      return Some(line)
    } else {
      for i = self.pos; i < self.len; i = i + 1 {
        acc.write_byte(self.buf[i])
      }
      self.pos = self.len
      if acc.length() > MAX_HEADER_BYTES {
        return None
      }
    }
  }
  None
}

///|
/// Read exactly `want` bytes into `dst`, draining the internal buffer
/// first. Returns how many bytes were actually read.
fn ConnReader::read_exact(
  self : ConnReader,
  dst : FixedArray[Byte],
  want : Int,
) -> Int {
  let mut filled = 0
  while filled < want {
    if self.pos < self.len {
      let avail = self.len - self.pos
      let take = if want - filled < avail { want - filled } else { avail }
      for i = 0; i < take; i = i + 1 {
        dst[filled + i] = self.buf[self.pos + i]
      }
      self.pos += take
      filled += take
    } else {
      self.pos = 0
      self.len = self.conn.read(self.buf)
      if self.len <= 0 {
        break
      }
    }
  }
  filled
}

///|
/// Read and parse one HTTP request from the connection, including a
/// Content-Length body when present. Returns None on malformed input.
pub fn ConnReader::read_request(self : ConnReader) -> @http.Request? {
  let start = match self.read_line() {
    Some(l) =>
      if l == "" {
        // tolerate a single leading blank line, as servers commonly do
        match self.read_line() {
          Some(l2) => l2
          None => return None
        }
      } else {
        l
      }
    None => return None
  }
  let head = StringBuilder(size_hint=512)
  head.write_string(start)
  head.write_string("\r\n")
  let mut count = 1
  while true {
    match self.read_line() {
      Some(l) =>
        if l == "" {
          break
        } else {
          head.write_string(l)
          head.write_string("\r\n")
          count += 1
          if count > MAX_HEADERS {
            return None
          }
        }
      None => break
    }
  }
  head.write_string("\r\n")
  let req = match @http.parse_request(head.to_string()) {
    Some(r) => r
    None => return None
  }
  let clen = match req.header("Content-Length") {
    Some(v) => @string.parse_int(v) catch { _ => 0 }
    None => 0
  }
  if clen <= 0 {
    return Some(req)
  }
  if clen > MAX_BODY_BYTES {
    return None
  }
  let dst : FixedArray[Byte] = FixedArray::make(clen, b'\x00')
  let got = self.read_exact(dst, clen)
  let arr : Array[Byte] = []
  for i = 0; i < got; i = i + 1 {
    arr.push(dst[i])
  }
  Some(req.with_body(Bytes::from_array(arr[:])))
}
