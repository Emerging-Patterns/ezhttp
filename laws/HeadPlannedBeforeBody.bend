# The client plans a response from its head before it touches the body's
# octets, with the same decisions the text parse makes. For every status
# code `m` (or none) and head lines `ls`, the head's plan (`head.plan`) is
# torn with `the response has no status line` when there is no status code;
# torn with `Content-Length values disagree` when its Content-Length values
# are not all the same digits (RFC 9112 §6.3 item 5); torn with
# `Content-Length and Transfer-Encoding conflict` when Transfer-Encoding
# names `chunked` and a Content-Length is present (RFC 9112 §6.3 item 3);
# chunked when Transfer-Encoding names `chunked` (item 4); sized by the
# Content-Length when it reads as a number; and framed by the close
# otherwise (item 8); and for every body, `parse_response`'s reading of that
# head and body is exactly what the plan says of the body (`plan.text`). For
# every method flag, head text and text after it whose head is not skipped
# as interim (laws/InterimResponsesSkipped.bend), the client's reading of
# that head and text is exactly `plan.text` of the final head's plan
# (`head.final`: no body for `HEAD`, 1xx, 204 or 304, RFC 9110 §6.4.1). For
# every chunk-size line `h` and the text `r` after it, the chunked decoder's
# step is decided by the line alone (`chunk.size`) and then `r`
# (`chunk.next`): `chunk size is not hexadecimal` when its size is not hex
# digits, the last chunk when the size is 0, and otherwise the next chunk
# header when that many octets and a CRLF follow, else `the chunked body
# stopped short` (RFC 9112 §7.1).
import Base
import ../src/http.bend as Http

# --- a response planned from its head ---

# LAW (RFC 9112 §4): a final head with no status code is torn
law plan_none:
  for ls: List<&2, String>
  {Http.head.plan(None{}, ls)
    == Http.Unplanned{"the response has no status line"} : Http.Plan}

# LAW (RFC 9112 §6.3 item 5): Content-Length values that are not all the
# same digits are torn
law plan_disagree:
  for n: U32
  for +ls: List<&2, String>
  for e: {False{} == Http.clen.agree(Http.head.values(ls, "content-length"))
    : Bool}
  {Http.head.plan(Some{n}, ls)
    == Http.Unplanned{"Content-Length values disagree"} : Http.Plan}

# LAW (RFC 9112 §6.3 item 3): chunked Transfer-Encoding with a
# Content-Length is torn
law plan_conflict:
  for n: U32
  for +ls: List<&2, String>
  for e1: {True{} == Http.clen.agree(Http.head.values(ls, "content-length"))
    : Bool}
  for e2: {True{} == String.contains(String.to_lower(Http.head.go(ls,
    "transfer-encoding")), "chunked") : Bool}
  for e3: {True{} == Http.clen.any(Http.head.values(ls, "content-length"))
    : Bool}
  {Http.head.plan(Some{n}, ls)
    == Http.Unplanned{"Content-Length and Transfer-Encoding conflict"}
    : Http.Plan}

# LAW (RFC 9112 §6.3 item 4): chunked Transfer-Encoding alone frames the
# body by its chunks
law plan_chunked:
  for n: U32
  for +ls: List<&2, String>
  for e1: {True{} == Http.clen.agree(Http.head.values(ls, "content-length"))
    : Bool}
  for e2: {True{} == String.contains(String.to_lower(Http.head.go(ls,
    "transfer-encoding")), "chunked") : Bool}
  for e3: {False{} == Http.clen.any(Http.head.values(ls, "content-length"))
    : Bool}
  {Http.head.plan(Some{n}, ls)
    == Http.Planned{n, Http.head.list(ls), Http.Chunked{}} : Http.Plan}

# LAW (RFC 9112 §6.3 item 6): otherwise a Content-Length that reads as a
# number sizes the body
law plan_sized:
  for n: U32
  for +ls: List<&2, String>
  for e1: {True{} == Http.clen.agree(Http.head.values(ls, "content-length"))
    : Bool}
  for e2: {False{} == String.contains(String.to_lower(Http.head.go(ls,
    "transfer-encoding")), "chunked") : Bool}
  for k: Nat
  for e3: {Some{k} == Http.digits.read(Http.first(Http.head.values(ls,
    "content-length"))) : Maybe<&2, Nat>}
  {Http.head.plan(Some{n}, ls)
    == Http.Planned{n, Http.head.list(ls), Http.Sized{k}} : Http.Plan}

# LAW (RFC 9112 §6.3 item 8): otherwise the body runs to the close
law plan_closed:
  for n: U32
  for +ls: List<&2, String>
  for e1: {True{} == Http.clen.agree(Http.head.values(ls, "content-length"))
    : Bool}
  for e2: {False{} == String.contains(String.to_lower(Http.head.go(ls,
    "transfer-encoding")), "chunked") : Bool}
  for e3: {None{} == Http.digits.read(Http.first(Http.head.values(ls,
    "content-length"))) : Maybe<&2, Nat>}
  {Http.head.plan(Some{n}, ls)
    == Http.Planned{n, Http.head.list(ls), Http.Closed{}} : Http.Plan}

# LAW: parse_response reads a head and its body as the head's plan says
law plan_status:
  for m: Maybe<&2, U32>
  for +ls: List<&2, String>
  for +body: String
  {Http.parse.status(m, ls, body) == Http.plan.text(Http.head.plan(m, ls), body)
    : Http.Reply}

# LAW (RFC 9110 §6.4.1, §9.3.2): a final head is read as its plan says, with
# no body for HEAD or a 1xx, 204 or 304 status
law plan_final:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.plan.text(Http.head.final(head, String.lines(before)), after)
    : Http.Reply}

# LAW (RFC 9112 §7.1): the chunked decoder's step is decided by the chunk-size
# line alone, then by the octets after it
law size_next:
  for +before: String
  for +after: String
  {Http.chunks.next(before, after)
    == Http.chunk.next(Http.chunk.size(before), after) : Http.Next}
