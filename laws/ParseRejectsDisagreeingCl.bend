import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a response whose Content-Length values differ is torn
law parse_rejects_disagreeing_cl:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\nab")
    == Http.Torn{"Content-Length values disagree"} : Http.Reply}
