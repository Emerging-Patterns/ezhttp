# For every request whose Content-Length values are all the same digits,
# the values agree (RFC 9112 §6.3): a repeated value adds nothing to the
# list it repeats. A request whose values agree and that is not chunked is
# framed by its first value alone, and a body longer than that value is
# cut to it.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a value repeating the first changes nothing
law clen_agree_repeat:
  for +v: String
  for w: String
  for rest: List<&2, String>
  for e: {True{} == String.eq(w, v) : Bool}
  {Http.clen.agree(v <> w <> rest) == Http.clen.agree(v <> rest) : Bool}

# LAW (RFC 9112 §6.3): agreeing values frame the body by the first one
law ask_equal_content_lengths:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for +te: String
  for +lens: List<&2, String>
  for body: String
  for ea: {True{} == Http.clen.agree(lens) : Bool}
  for ec: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  {Http.ask.frame(method, target, hs, te, lens, body)
    == Http.ask.len(method, target, hs, Http.digits.read(Http.first(lens)),
      body) : Http.Request}

# LAW (RFC 9112 §6.3): a body longer than Content-Length is cut to it
law ask_clen_takes_prefix:
  for +method: String
  for +target: String
  for hs: List<&2, Http.Header>
  for +n: Nat
  for +body: String
  for e: {False{} == Nat.is_lt(Http.octs.len(body), n) : Bool}
  {Http.ask.clen(method, target, hs, n, body)
    == Http.Request{method, target, hs, Http.octs.take(body, n)}
    : Http.Request}
