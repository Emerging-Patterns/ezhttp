import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.1): origin-form keeps an absolute-path and its query
law ask_origin_form_keeps_query:
  {Http.ask("GET /ok?a=1 HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Request{"GET", "/ok?a=1", [Http.H{"Host", "h"}], ""} : Http.Request}
