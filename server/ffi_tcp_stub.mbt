// Non-native targets (wasm-gc / js) expose no socket API. The raw
// primitives report failure so the whole server still compiles and its
// request-processing logic runs against in-memory connections (see
// conn_test.mbt and handler_test.mbt).

///|
fn tinyhttpd_socket_open(_port : Int) -> Int {
  -1
}

///|
fn tinyhttpd_accept(_listen_sock : Int) -> Int {
  -1
}

///|
fn tinyhttpd_read(_sock : Int, _buf : FixedArray[Byte], _len : Int) -> Int {
  -1
}

///|
fn tinyhttpd_write(
  _sock : Int,
  _buf : FixedArray[Byte],
  _offset : Int,
  _len : Int,
) -> Int {
  -1
}

///|
fn tinyhttpd_close(_sock : Int) -> Unit {
  ()
}
