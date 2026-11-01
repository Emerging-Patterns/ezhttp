import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): with neither framing header the rest of the connection
# is the body (Connection: close)
law unframed_is_rest:
  for st: U32
  for hs: List<&2, Http.Header>
  for body: String
  {Http.parse.len(st, hs, None{}, body) == Http.Reply{st, hs, body}
    : Http.Reply}
