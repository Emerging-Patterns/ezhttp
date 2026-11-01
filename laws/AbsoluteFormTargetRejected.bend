import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.2): absolute-form is not accepted as origin-form
law ask_rejects_absolute_form:
  {Http.ask("GET http://example.com/a HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
