import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §2.1): a request whose header section never ended is bad
law ask_needs_blank_line:
  for +raw: String
  for e: {Http.NoCut{} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.ask(raw) == Http.Bad{"the request head has no blank line after it"}
    : Http.Request}
