import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.4): asterisk-form is not a GET target
law ask_get_asterisk_rejected:
  {Http.ask("GET * HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
