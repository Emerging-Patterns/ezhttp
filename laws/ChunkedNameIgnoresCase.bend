import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): chunked is recognized in any case
law parse_chunked_ignores_case:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: CHUNKED\r\n\r\n1\r\nZ\r\n0\r\n\r\n")
    == Http.Reply{200, [Http.H{"Transfer-Encoding", "CHUNKED"}], "Z"}
    : Http.Reply}
