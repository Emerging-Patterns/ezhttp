# For every request whose Content-Length values disagree, the request is
# bad before any framing (RFC 9112 §6.3): two values that are not the same
# digits disagree, wherever they come in the list, and a list that
# disagrees frames no body.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a second value unlike the first disagrees
law clen_disagree:
  for +v: String
  for w: String
  for rest: List<&2, String>
  for e: {False{} == String.eq(w, v) : Bool}
  {Http.clen.agree(v <> w <> rest) == False{} : Bool}

# LAW (RFC 9112 §6.3): disagreeing Content-Length values are a bad request
law ask_rejects_disagreeing_cl:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for te: String
  for +lens: List<&2, String>
  for body: String
  for e: {False{} == Http.clen.agree(lens) : Bool}
  {Http.ask.frame(method, target, hs, te, lens, body)
    == Http.Bad{"Content-Length values disagree"} : Http.Request}
