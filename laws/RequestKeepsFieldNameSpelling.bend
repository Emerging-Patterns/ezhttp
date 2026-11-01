import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1): the wire spelling of a field name is kept
law ask_keeps_field_name_spelling:
  {Http.ask("GET / HTTP/1.1\r\nhOsT: Ex.COM\r\n\r\n")
    == Http.Request{"GET", "/", [Http.H{"hOsT", "Ex.COM"}], ""} : Http.Request}
