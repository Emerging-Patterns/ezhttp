import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a non-hexadecimal chunk size is torn
law parse_rejects_non_hex_chunk:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nZ\r\n\r\n")
    == Http.Torn{"chunk size is not hexadecimal"} : Http.Reply}
