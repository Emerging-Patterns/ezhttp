import Base
import ../src/http.bend as Http

# LAW: a request body shorter than Content-Length is bad
law ask_clen_short:
  for +method: String
  for +target: String
  for hs: List<&2, Http.Header>
  for +n: Nat
  for +body: String
  for e: {True{} == Nat.is_lt(Http.octs.len(body), n) : Bool}
  {Http.ask.clen(method, target, hs, n, body)
    == Http.Bad{"the request body stopped before its Content-Length"}
    : Http.Request}
