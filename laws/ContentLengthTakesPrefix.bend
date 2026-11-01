import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): Content-Length takes that many octets and no more
law parse_clen_takes_prefix:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Reply{200, [Http.H{"Content-Length", "5"}], "hello"} : Http.Reply}
