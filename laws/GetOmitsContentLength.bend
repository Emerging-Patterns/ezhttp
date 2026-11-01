import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): an empty GET omits Content-Length
law get_omits_content_length:
  {Http.get_req("h", "/", [])
    == "GET / HTTP/1.1\r\n"
      ++ "Host: h\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ "\r\n"
    : String}
