import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): identical Content-Length values are that one length
law parse_equal_content_lengths:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 5\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Reply{200, [Http.H{"Content-Length", "5"},
      Http.H{"Content-Length", "5"}], "hello"} : Http.Reply}
