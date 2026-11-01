import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): two non-empty chunks round-trip
law dechunk_two_chunks:
  {Http.dechunk("1\r\nZ\r\n2\r\nOK\r\n0\r\n\r\n") == "ZOK" : String}
