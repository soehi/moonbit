// Raw TCP primitives for the native backend: thin extern wrappers over
// the C shim in ffi_tcp_native.c. Only integers and byte buffers cross
// the boundary, so marshalling is trivial and GC-safe.

///|
/// Bind and listen on all interfaces. Returns the listen handle or -1.
extern "C" fn tinyhttpd_socket_open(port : Int) -> Int = "tinyhttpd_socket_open"

///|
/// Block until one client connects. Returns the client handle or -1.
extern "C" fn tinyhttpd_accept(listen_sock : Int) -> Int = "tinyhttpd_accept"

///|
/// Blocking receive; returns bytes read (0 on EOF, -1 on error).
#borrow(buf)
extern "C" fn tinyhttpd_read(
  sock : Int,
  buf : FixedArray[Byte],
  len : Int,
) -> Int = "tinyhttpd_read"

///|
/// Blocking send from `offset`; returns bytes written or -1.
#borrow(buf)
extern "C" fn tinyhttpd_write(
  sock : Int,
  buf : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tinyhttpd_write"

///|
extern "C" fn tinyhttpd_close(sock : Int) -> Unit = "tinyhttpd_close"
