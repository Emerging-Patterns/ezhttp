import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): a non-empty request body is framed by Content-Length
law post_writes_content_length:
  {Http.request("POST", "h", "/a", [], "hi")
    == "POST /a HTTP/1.1\r\n"
      ++ "Host: h\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ "Content-Length: 2\r\n"
      ++ "\r\n"
      ++ "hi"
    : String}
