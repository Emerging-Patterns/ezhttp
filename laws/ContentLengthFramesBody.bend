# For every status, header fields, body octets `b` and octets `r` after
# them, a response framed by a Content-Length of exactly `b`'s octets is
# `b`, whatever `r` holds (RFC 9112 §6.3 item 5: octets past the length are
# not the message's), and one whose octets after the head are fewer than its
# Content-Length is torn with `the response body stopped before its
# Content-Length`.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §6.3): a body shorter than its Content-Length is torn — a cut
# connection is not a short file.
law clen_short:
  for st: U32
  for hs: List<&2, Http.Header>
  for +n: Nat
  for +body: String
  for e: {True{} == Nat.is_lt(Http.octs.len(body), n) : Bool}
  {Http.parse.clen(st, hs, n, body)
    == Http.Torn{"the response body stopped before its Content-Length"}
    : Http.Reply}

# LAW (RFC 9112 §6.3 item 5): a body framed by a Content-Length of exactly
# its octets is those octets, whatever follows them
law clen_prefix:
  for st: U32
  for hs: List<&2, Http.Header>
  for +b: String
  for +r: String
  {Http.parse.clen(st, hs, String.length(b), String.append(b, r))
    == Http.Reply{st, hs, b}
    : Http.Reply}
