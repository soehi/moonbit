// Content-Type mapping, ported in spirit from tinyhttpd's get_MIME_type.

///|
/// Best-effort Content-Type for a file name, by extension
/// (case-insensitive). Unknown extensions default to
/// application/octet-stream.
pub fn mime_type(name : String) -> String {
  let lower = name.to_lower()
  if lower.has_suffix(".html") || lower.has_suffix(".htm") {
    "text/html"
  } else if lower.has_suffix(".css") {
    "text/css"
  } else if lower.has_suffix(".js") {
    "application/javascript"
  } else if lower.has_suffix(".json") {
    "application/json"
  } else if lower.has_suffix(".txt") || lower.has_suffix(".cgi") {
    "text/plain"
  } else if lower.has_suffix(".png") {
    "image/png"
  } else if lower.has_suffix(".jpg") || lower.has_suffix(".jpeg") {
    "image/jpeg"
  } else if lower.has_suffix(".gif") {
    "image/gif"
  } else if lower.has_suffix(".svg") {
    "image/svg+xml"
  } else if lower.has_suffix(".ico") {
    "image/x-icon"
  } else {
    "application/octet-stream"
  }
}
