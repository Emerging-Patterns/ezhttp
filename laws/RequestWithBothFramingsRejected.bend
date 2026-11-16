# For every request that sends a Content-Length field and a chunked
# Transfer-Encoding whose Content-Length values agree, the two framings
# conflict and the request is bad (RFC 9112 §6.3).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): Content-Length with chunked framing is a bad request
law ask_rejects_cl_and_te:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for +te: String
  for +l: String
  for +ls: List<&2, String>
  for body: String
  for ea: {True{} == Http.clen.agree(l <> ls) : Bool}
  for ec: {True{} == String.contains(String.to_lower(te), "chunked") : Bool}
  {Http.ask.frame(method, target, hs, te, l <> ls, body)
    == Http.Bad{"Content-Length and Transfer-Encoding conflict"}
    : Http.Request}
