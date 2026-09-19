///|
test "cgi env mirrors the meta-variables" {
  let req = @http.parse_request(
    "GET /cgi-bin/env.cgi?name=Jim HTTP/1.0\r\nUser-Agent: Probe\r\n\r\n",
  ).unwrap()
  let env = cgi_env(req, server_port="8080")
  inspect(env.get("REQUEST_METHOD") == Some("GET"), content="true")
  inspect(env.get("QUERY_STRING") == Some("name=Jim"), content="true")
  inspect(env.get("SERVER_PROTOCOL") == Some("HTTP/1.0"), content="true")
  inspect(env.get("PATH_INFO") == Some("/cgi-bin/env.cgi"), content="true")
  inspect(env.get("CONTENT_LENGTH") == Some(""), content="true")
  inspect(env.get("HTTP_USER_AGENT") == Some("Probe"), content="true")
}

///|
test "render ssi expands and defaults to none" {
  let env : Map[String, String] = Map([])
  env["QUERY_STRING"] = "name=Jim"
  let html = render_ssi(
    "<p><!--#echo var=\"QUERY_STRING\" --></p><!--#echo var=\"MISSING\" -->", env,
  )
  inspect(html, content="<p>name=Jim</p>(none)")
}

///|
test "render ssi passes plain text through" {
  inspect(render_ssi("no directives", Map([])), content="no directives")
  inspect(render_ssi("", Map([])), content="")
}

///|
test "cgi_fn adapter wraps a function" {
  let prog = cgi_fn(fn(req) { @http.Response::error(418, req.path) })
  let req = @http.parse_request("GET /teapot HTTP/1.0\r\n\r\n").unwrap()
  inspect(prog.run(req).status, content="418")
}
