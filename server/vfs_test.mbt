///|
test "normalize path" {
  inspect(normalize_path("/a/./b/../c"), content="/a/c")
  inspect(normalize_path("/../etc/passwd"), content="/etc/passwd")
  inspect(normalize_path("//x///y//"), content="/x/y")
  inspect(normalize_path(".."), content="/")
  inspect(normalize_path(""), content="/")
}

///|
test "vfs roundtrip and traversal containment" {
  let vfs = Vfs::new()
  vfs.add_string("/data/secret.txt", "text/plain", "hi")
  inspect(vfs.get("/data/secret.txt") is None, content="false")
  inspect(vfs.get("/data/./secret.txt") is None, content="false")
  inspect(vfs.get("/../data/secret.txt") is None, content="false")
  inspect(vfs.get("/etc/passwd") is None, content="true")
  let f = vfs.get("/data/secret.txt").unwrap()
  inspect(f.content_type, content="text/plain")
  inspect(@utf8.decode_lossy(f.bytes.view()), content="hi")
}
