///|
test "mime types" {
  inspect(mime_type("INDEX.HTML"), content="text/html")
  inspect(mime_type("style.css"), content="text/css")
  inspect(mime_type("app.js"), content="application/javascript")
  inspect(mime_type("photo.jpeg"), content="image/jpeg")
  inspect(mime_type("notes.txt"), content="text/plain")
  inspect(mime_type("noext"), content="application/octet-stream")
  inspect(mime_type(""), content="application/octet-stream")
}
