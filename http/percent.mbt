// Percent-encoding and query-string handling, ported in spirit from the
// URL decoding tinyhttpd performs before dispatching CGI requests.

///|
fn hex_val(b : Byte) -> Int? {
  let v = b.to_int()
  if v >= 0x30 && v <= 0x39 {
    Some(v - 0x30)
  } else if v >= 0x41 && v <= 0x46 {
    Some(v - 0x41 + 10)
  } else if v >= 0x61 && v <= 0x66 {
    Some(v - 0x61 + 10)
  } else {
    None
  }
}

///|
/// Decode percent-escapes in `input`. When `plus_as_space` is true (HTML
/// form data), '+' decodes to a space. Malformed escapes are kept
/// literally, matching the forgiving behaviour of the original tinyhttpd.
pub fn percent_decode(input : String, plus_as_space~ : Bool = false) -> String {
  let bytes = @utf8.encode(input)
  let n = bytes.length()
  let out = Buffer()
  let mut i = 0
  while i < n {
    let b = bytes[i]
    if b == b'+' && plus_as_space {
      out.write_byte(b' ')
      i += 1
    } else if b == b'%' && i + 2 < n {
      match (hex_val(bytes[i + 1]), hex_val(bytes[i + 2])) {
        (Some(hi), Some(lo)) => {
          out.write_byte(((hi * 16) + lo).to_byte())
          i += 3
        }
        _ => {
          out.write_byte(b)
          i += 1
        }
      }
    } else {
      out.write_byte(b)
      i += 1
    }
  }
  @utf8.decode_lossy(out.to_bytes().view())
}

///|
/// Parse a query string like "name=Jim&color=%2300ff00" into a map.
/// Both keys and values are percent-decoded; '+' counts as space.
/// A repeated key keeps its last value.
pub fn parse_query(query : String) -> Map[String, String] {
  let params : Map[String, String] = Map([])
  for pair in query.split("&") {
    let pair = pair.to_owned()
    if pair != "" {
      match pair.split_once("=") {
        Some((k, v)) => {
          let key = percent_decode(k.to_owned(), plus_as_space=true)
          let value = percent_decode(v.to_owned(), plus_as_space=true)
          params[key] = value
        }
        None => params[percent_decode(pair, plus_as_space=true)] = ""
      }
    }
  }
  params
}
