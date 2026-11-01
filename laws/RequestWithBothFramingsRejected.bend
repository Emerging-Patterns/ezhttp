import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a request with both framings is bad
law ask_rejects_cl_and_te:
  {Http.ask("POST / HTTP/1.1\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n")
    == Http.Bad{"Content-Length and Transfer-Encoding conflict"} : Http.Request}
