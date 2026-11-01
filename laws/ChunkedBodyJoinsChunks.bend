import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a chunked response body is the concatenated chunks
law parse_chunked_body:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwiki\r\n5\r\npedia\r\n0\r\n\r\n")
    == Http.Reply{200, [Http.H{"Transfer-Encoding", "chunked"}], "wikipedia"}
    : Http.Reply}
