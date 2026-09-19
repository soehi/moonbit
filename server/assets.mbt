// Bundled pages of the demo document root (htdocs). Keeping them in
// source makes the server a single self-contained binary on every
// target; the content mirrors the pages the original tinyhttpd shipped.

///|
fn index_html() -> String {
  "<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<title>tiny-httpd-moonbit</title>\n<link rel=\"stylesheet\" href=\"/styles.css\">\n</head>\n<body>\n<h1>It works! tiny-httpd-moonbit</h1>\n<p>This page is served by a ~600 line HTTP server written in pure MoonBit,\nported from J. David Blackstone's classic tinyhttpd (1999).</p>\n<ul>\n<li><a href=\"/cgi-bin/env.cgi?name=Jim\">env.cgi</a>: dumps the CGI environment</li>\n<li><a href=\"/cgi-bin/color.cgi?color=%2336a\">color.cgi</a>: dynamic HTML in your color</li>\n</ul>\n</body>\n</html>\n"
}

///|
fn styles_css() -> String {
  "body { font-family: sans-serif; margin: 3rem auto; max-width: 40rem; }\nh1 { color: #244; }\nli { margin: 0.5rem 0; }\n"
}

///|
/// env.cgi, ported from the original shell script: in this port it is a
/// server-parsed template; every directive is replaced with the CGI
/// meta-variable of the current request.
fn env_cgi_script() -> String {
  "<html>\n<head><title>CGI environment</title></head>\n<body>\n<h1>CGI Environment</h1>\n<table border=\"1\">\n<tr><td>SERVER_SOFTWARE</td><td><!--#echo var=\"SERVER_SOFTWARE\" --></td></tr>\n<tr><td>SERVER_NAME</td><td><!--#echo var=\"SERVER_NAME\" --></td></tr>\n<tr><td>GATEWAY_INTERFACE</td><td><!--#echo var=\"GATEWAY_INTERFACE\" --></td></tr>\n<tr><td>SERVER_PROTOCOL</td><td><!--#echo var=\"SERVER_PROTOCOL\" --></td></tr>\n<tr><td>SERVER_PORT</td><td><!--#echo var=\"SERVER_PORT\" --></td></tr>\n<tr><td>REQUEST_METHOD</td><td><!--#echo var=\"REQUEST_METHOD\" --></td></tr>\n<tr><td>PATH_INFO</td><td><!--#echo var=\"PATH_INFO\" --></td></tr>\n<tr><td>QUERY_STRING</td><td><!--#echo var=\"QUERY_STRING\" --></td></tr>\n<tr><td>CONTENT_LENGTH</td><td><!--#echo var=\"CONTENT_LENGTH\" --></td></tr>\n<tr><td>HTTP_USER_AGENT</td><td><!--#echo var=\"HTTP_USER_AGENT\" --></td></tr>\n<tr><td>HTTP_ACCEPT</td><td><!--#echo var=\"HTTP_ACCEPT\" --></td></tr>\n</table>\n</body>\n</html>\n"
}
