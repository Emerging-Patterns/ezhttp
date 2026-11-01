# For every request method and every text received so far, the response is
# complete exactly when its header section has ended (RFC 9112 §2.1) and
# then: when the head's status is 1xx it is an interim response (RFC 9110
# §15.2), and the response is complete exactly when the text after that head
# is, read the same way (so never while nothing follows it), at most as many
# heads deep as the text has characters; otherwise its framing (RFC 9112
# §6.3) says the body has arrived: the request was `HEAD` or the status is
# 204 or 304, so there is no body; otherwise Transfer-Encoding names
# `chunked` and the body has reached the end of its last chunk, read chunk
# by chunk (each a hexadecimal size, CRLF, that many octets, CRLF), meaning
# a zero size followed by an ended trailer section, or a size that is not
# hexadecimal (the parse then rejects it); otherwise every Content-Length
# value is the same decimal `n` and the body holds at least `n` octets. A
# response with none of these framings (no Content-Length, or values that
# disagree or do not parse) is never complete before the server closes the
# connection.
#
# also rests on: laws/InterimStatusIs1xx.bend
import Base
import ../src/http.bend as Http

# --- when a response is whole ---

# LAW: a text is read head by head for the request's method, at most as many
# heads as it has characters
law whole_go:
  for +method: String
  for +raw: String
  {Http.whole(method, raw)
    == Http.whole.go(String.length(raw), String.eq(method, "HEAD"),
      Http.divide(raw, "\r\n\r\n")) : Bool}

# LAW: a read with no heads left is not whole
law whole_fuel:
  for asked: Bool
  for c: Http.Cut
  {Http.whole.go(0n, asked, c) == False{} : Bool}

# LAW (RFC 9112 §2.1): a response whose header section has not ended is not
# whole
law whole_open:
  for f: Nat
  for asked: Bool
  {Http.whole.go(1n+f, asked, Http.NoCut{}) == False{} : Bool}

# LAW (RFC 9110 §15.2): after an interim (1xx) head, the response is whole
# exactly when the text after that head is
law whole_interim:
  for f: Nat
  for +asked: Bool
  for +before: String
  for +after: String
  for e: {True{} == Http.status.interim(Http.status.of(String.lines(before)))
    : Bool}
  {Http.whole.go(1n+f, asked, Http.Cut{before, after})
    == Http.whole.go(f, asked, Http.divide(after, "\r\n\r\n")) : Bool}

# LAW (RFC 9112 §6.3): once a final header section has ended, a response is
# whole exactly when its body is, under the framing its head and the
# request's method give
law whole_head:
  for f: Nat
  for +asked: Bool
  for +before: String
  for +after: String
  for e: {False{} == Http.status.interim(Http.status.of(String.lines(before)))
    : Bool}
  {Http.whole.go(1n+f, asked, Http.Cut{before, after})
    == Http.whole.of(Http.frame(Bool.or(asked,
      Http.status.bare(Http.status.of(String.lines(before)))),
      Http.head.go(String.lines(before), "transfer-encoding"),
      Http.head.values(String.lines(before), "content-length")), after)
    : Bool}

# LAW (RFC 9112 §4): a status line's code is its second word, as a number
law status_of:
  for ls: List<&2, String>
  {Http.status.of(ls) == U32.read(Http.second(String.split(Http.first(ls), ' ')))
    : Maybe<&2, U32>}

# LAW (RFC 9110 §15.3.5, §15.4.5): a 204 or a 304 has no body
law status_bare_some:
  for +n: U32
  {Http.status.bare(Some{n}) == Bool.or(U32.is_eq(n, 204), U32.is_eq(n, 304))
    : Bool}

# LAW: a status line that does not parse leaves the framing to the headers
law status_bare_none:
  for m: Maybe<&2, U32>
  for e: {None{} == m : Maybe<&2, U32>}
  {Http.status.bare(m) == False{} : Bool}

# LAW (RFC 9110 §9.3.2, RFC 9112 §6.3 item 1): a reply to HEAD, a 204 and a
# 304 have no body, whatever their fields say
law frame_bare:
  for te: String
  for lens: List<&2, String>
  {Http.frame(True{}, te, lens) == Http.Bare{} : Http.Frame}

# LAW (RFC 9112 §6.3 items 3, 4): Transfer-Encoding chunked frames the body,
# Content-Length or not
law frame_chunked:
  for te: String
  for +lens: List<&2, String>
  for e: {True{} == String.contains(String.to_lower(te), "chunked") : Bool}
  {Http.frame(False{}, te, lens) == Http.Chunked{} : Http.Frame}

# LAW (RFC 9112 §6.3 item 6): otherwise Content-Length values that agree on
# a number frame the body at that many octets
law frame_sized:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {True{} == Http.clen.agree(lens) : Bool}
  for n: Nat
  for e3: {Some{n} == Http.digits.read(Http.first(lens)) : Maybe<&2, Nat>}
  {Http.frame(False{}, te, lens) == Http.Sized{n} : Http.Frame}

# LAW (RFC 9112 §6.3 items 5, 8): Content-Length values that disagree leave
# the body to the close
law frame_disagree:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {False{} == Http.clen.agree(lens) : Bool}
  {Http.frame(False{}, te, lens) == Http.Closed{} : Http.Frame}

# LAW (RFC 9112 §6.3 item 8): no Content-Length, or one that is not a
# number, leaves the body to the close
law frame_unsized:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {True{} == Http.clen.agree(lens) : Bool}
  for e3: {None{} == Http.digits.read(Http.first(lens)) : Maybe<&2, Nat>}
  {Http.frame(False{}, te, lens) == Http.Closed{} : Http.Frame}

# LAW: a response with no body is whole as soon as its head is
law whole_bare:
  for +body: String
  {Http.whole.of(Http.Bare{}, body) == True{} : Bool}

# LAW (RFC 9110 §8.6): a sized body is whole once it holds that many octets
law whole_sized:
  for n: Nat
  for +body: String
  {Http.whole.of(Http.Sized{n}, body)
    == Bool.not(Nat.is_lt(Http.octs.len(body), n)) : Bool}

# LAW (RFC 9112 §7.1): a chunked body is whole once it reaches the end of its
# last chunk, read from its first chunk header
law whole_chunked:
  for +body: String
  {Http.whole.of(Http.Chunked{}, body)
    == Http.chunks.ended(String.length(body), Http.divide(body, "\r\n"))
    : Bool}

# LAW (RFC 9112 §6.3 item 8): a body framed by the close is never whole
# before the close
law whole_closed:
  for +body: String
  {Http.whole.of(Http.Closed{}, body) == False{} : Bool}

# LAW: a chunk walk with no fuel left has not ended
law ended_fuel:
  for c: Http.Cut
  {Http.chunks.ended(0n, c) == False{} : Bool}

# LAW (RFC 9112 §7.1): a chunk header that has not all arrived has not ended
law ended_open:
  for f: Nat
  {Http.chunks.ended(1n+f, Http.NoCut{}) == False{} : Bool}

# LAW (RFC 9112 §7.1): a chunk size that is not hexadecimal ends the read,
# and the parse rejects it
law ended_bad:
  for f: Nat
  for +before: String
  for +after: String
  for e: {False{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after}) == True{} : Bool}

# LAW (RFC 9112 §7.1.2): the zero-size chunk ends the body once its trailer
# section has ended
law ended_last:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {True{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after})
    == Http.chunks.trailer(after) : Bool}

# LAW (RFC 9112 §7.1): a chunk that has all arrived, with its CRLF, moves on
# to the next chunk header
law ended_next:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {False{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  for e3: {True{} == Http.chunks.ready(after, Http.hexlen(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after})
    == Http.chunks.ended(f, Http.divide(Http.octs.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}

# LAW (RFC 9112 §7.1): a chunk that has not all arrived has not ended
law ended_short:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {False{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  for e3: {False{} == Http.chunks.ready(after, Http.hexlen(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after}) == False{} : Bool}

# LAW (RFC 9112 §7.1.2): a trailer section has ended at once (CRLF), or after
# its fields (a blank line)
law trailer_ended:
  for +after: String
  {Http.chunks.trailer(after) == Bool.or(String.starts_with(after, "\r\n"),
    String.contains(after, "\r\n\r\n")) : Bool}

# LAW (RFC 9112 §7.1): a chunk of size n has arrived when n octets and a
# CRLF follow its header
law chunk_ready:
  for +after: String
  for +n: Nat
  {Http.chunks.ready(after, n)
    == Bool.and(Bool.not(Nat.is_lt(Http.octs.len(after), Nat.add(n, 2n))),
      String.starts_with(Http.octs.drop(after, n), "\r\n")) : Bool}
