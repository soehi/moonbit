// In-memory document root. The original tinyhttpd served files straight
// from disk with fopen/fgets; this port ships its pages inside the
// binary instead, so the server is a single self-contained executable
// and directory traversal is impossible by construction.

///|
/// One file in the in-memory document root.
pub struct VfsFile {
  bytes : Bytes
  content_type : String
}

///|
/// Read-only in-memory document root mapping normalized paths to files.
pub struct Vfs {
  files : Map[String, VfsFile]
}

///|
pub fn Vfs::new() -> Vfs {
  { files: Map([]) }
}

///|
/// Insert a file under `path` (a leading '/' is optional).
pub fn Vfs::add(
  self : Vfs,
  path : String,
  content_type : String,
  bytes : Bytes,
) -> Unit {
  self.files[normalize_path(path)] = { bytes, content_type }
}

///|
/// Insert a text file (encoded as UTF-8).
pub fn Vfs::add_string(
  self : Vfs,
  path : String,
  content_type : String,
  content : String,
) -> Unit {
  self.add(path, content_type, @utf8.encode(content))
}

///|
pub fn Vfs::get(self : Vfs, path : String) -> VfsFile? {
  self.files.get(normalize_path(path))
}

///|
/// Normalize a URL path: collapse duplicate slashes, drop "." segments
/// and resolve ".." against the segments before it. The result always
/// starts with '/' and can never address anything outside the flat
/// in-memory map.
pub fn normalize_path(path : String) -> String {
  let stack : Array[String] = []
  for seg in path.split("/") {
    let seg = seg.to_owned()
    if seg == "" || seg == "." {
      continue
    } else if seg == ".." {
      let _ = stack.pop()
    } else {
      stack.push(seg)
    }
  }
  let out = StringBuilder(size_hint=path.length())
  for seg in stack {
    out.write_string("/")
    out.write_string(seg)
  }
  if stack.is_empty() {
    "/"
  } else {
    out.to_string()
  }
}
