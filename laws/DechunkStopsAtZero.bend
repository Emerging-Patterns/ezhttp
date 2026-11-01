import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): the chunk of size 0 ends the body; a trailer is not data
law dechunk_stops_at_zero:
  {Http.dechunk("5\r\nhello\r\n0\r\nIgnored: 1\r\n\r\n") == "hello" : String}
