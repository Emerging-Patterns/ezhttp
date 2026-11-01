import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): Content-Length and Transfer-Encoding together are torn
law parse_rejects_cl_and_te:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n")
    == Http.Torn{"Content-Length and Transfer-Encoding conflict"} : Http.Reply}
