import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3): an empty request-line list is bad
law ask_needs_request_line:
  for body: String
  {Http.ask.head([], body) == Http.Bad{"the request has no request line"}
    : Http.Request}
