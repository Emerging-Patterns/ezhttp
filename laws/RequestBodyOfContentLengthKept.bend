import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6): a request body whose Content-Length matches comes back
law ask_clen_exact:
  for +method: String
  for +target: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.ask.clen(method, target, hs, Http.octs.len(body), body)
    == Http.Request{method, target, hs, body} : Http.Request}
