///|
test "parse get with query and headers" {
  let raw = "GET /cgi-bin/env.cgi?name=Jim HTTP/1.0\r\nUser-Agent: Mozilla/4.0\r\nAccept: */*\r\n\r\n"
  let req = parse_request(raw).unwrap()
  inspect(req.verb.to_string(), content="GET")
  inspect(req.path, content="/cgi-bin/env.cgi")
  inspect(req.raw_query, content="name=Jim")
  inspect(req.param("name") == Some("Jim"), content="true")
  inspect(req.version, content="HTTP/1.0")
  inspect(req.header("user-agent") == Some("Mozilla/4.0"), content="true")
  inspect(req.header("ACCEPT") == Some("*/*"), content="true")
  inspect(req.body.length(), content="0")
}

///|
test "parse post with body" {
  let raw = "POST /cgi-bin/color.cgi HTTP/1.0\r\nContent-Length: 11\r\n\r\nhello=world"
  let req = parse_request(raw).unwrap()
  inspect(req.verb.to_string(), content="POST")
  inspect(@utf8.decode_lossy(req.body.view()), content="hello=world")
  inspect(req.header("Content-Length") == Some("11"), content="true")
}

///|
test "parse rejects malformed request line" {
  inspect(parse_request("nonsense") is None, content="true")
  inspect(parse_request("GET no-slash HTTP/1.0\r\n\r\n") is None, content="true")
  inspect(parse_request("TELEPORT / HTTP/1.0\r\n\r\n") is None, content="true")
  inspect(parse_request("") is None, content="true")
}

///|
test "parse tolerates lf only endings" {
  let req = parse_request("GET /x?y=1 HTTP/1.0\nHost: a\n\n").unwrap()
  inspect(req.path, content="/x")
  inspect(req.param("y") == Some("1"), content="true")
  inspect(req.header("host") == Some("a"), content="true")
}

///|
test "with_body replaces payload" {
  let req = parse_request("POST / HTTP/1.0\r\n\r\n").unwrap().with_body(b"data")
  inspect(@utf8.decode_lossy(req.body.view()), content="data")
}
