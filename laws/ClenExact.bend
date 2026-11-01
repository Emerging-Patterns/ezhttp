import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §8.6 / RFC 9112 §6.3): a body whose Content-Length is its own
# octet count comes back exactly.
law clen_exact:
  for st: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.parse.clen(st, hs, Http.octs.len(body), body)
    == Http.Reply{st, hs, body} : Http.Reply}
