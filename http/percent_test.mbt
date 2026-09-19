///|
test "percent decode" {
  inspect(percent_decode("hello%20world"), content="hello world")
  inspect(percent_decode("%2Fetc%2Fpasswd"), content="/etc/passwd")
  inspect(percent_decode("a+b", plus_as_space=true), content="a b")
  inspect(percent_decode("a+b"), content="a+b")
  inspect(percent_decode("100%"), content="100%")
  inspect(percent_decode("%zz"), content="%zz")
  inspect(percent_decode("%e4%bd%a0%e5%a5%bd"), content="你好")
  inspect(percent_decode(""), content="")
}

///|
test "parse query" {
  let q = parse_query("name=Jim&color=%2300ff00&flag")
  inspect(q.get("name") == Some("Jim"), content="true")
  inspect(q.get("color") == Some("#00ff00"), content="true")
  inspect(q.get("flag") == Some(""), content="true")
  inspect(q.get("missing") == None, content="true")
  let repeated = parse_query("a=1&a=2")
  inspect(repeated.get("a") == Some("2"), content="true")
}
