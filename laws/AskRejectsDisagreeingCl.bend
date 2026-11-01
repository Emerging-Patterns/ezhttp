import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): Content-Length values that differ are a bad request
law ask_rejects_disagreeing_cl:
  {Http.ask("GET / HTTP/1.1\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\nab")
    == Http.Bad{"Content-Length values disagree"} : Http.Request}
