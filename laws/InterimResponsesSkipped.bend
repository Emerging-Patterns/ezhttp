# For every request method and every text an exchange answers with, the
# client reads the response with the method in mind: a head whose status is
# 1xx (RFC 9110 §15.2) with more text after it is an interim response and is
# skipped, the text after it read in its place, at most as many heads deep
# as the text has characters; the head it stops at is the final response.
# When the method is exactly `HEAD`, or the final status is 1xx, 204 or 304
# (RFC 9110 §6.4.1, §9.3.2; RFC 9112 §6.3 item 1), the response is that
# status, its header fields and an empty body, whatever its Content-Length
# or Transfer-Encoding say; otherwise it is exactly what `parse_response`
# reads from that head and the text after it. A text whose head never ends
# is torn with `the response head has no blank line after it`, and a final
# head with no status code with `the response has no status line`. A failed
# exchange keeps its reason as laws/TimeoutsReadAsTimedOut.bend reports it.
#
# also rests on: laws/InterimStatusIs1xx.bend
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec

# LAW: when the head did end, parse uses everything before/after the blank line
law parse_splits_at_blank_line:
  for +raw: String
  for before: String
  for after: String
  for e: {Http.Cut{before, after} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.parse(raw) == Http.parse.head(String.lines(before), after)
    : Http.Reply}

# --- the response, read by the request's method ---

# LAW: a response is read head by head for the request's method, at most as
# many heads as the text has characters
law reply_to:
  for +method: String
  for +raw: String
  {Http.parse.to(method, raw)
    == Http.parse.to.go(String.length(raw), String.eq(method, "HEAD"),
      Http.divide(raw, "\r\n\r\n")) : Http.Reply}

# LAW: a read with no heads left found no final head
law reply_fuel:
  for head: Bool
  for c: Http.Cut
  {Http.parse.to.go(0n, head, c)
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}

# LAW (RFC 9112 §2.1): a head that never ends is torn
law reply_open:
  for f: Nat
  for head: Bool
  {Http.parse.to.go(1n+f, head, Http.NoCut{})
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}

# LAW (RFC 9110 §15.2): an interim head with text after it is skipped, and the
# text after it is read in its place
law reply_interim:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e: {True{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.parse.to.go(f, head, Http.divide(after, "\r\n\r\n")) : Http.Reply}

# LAW (RFC 9110 §6.4.1, §9.3.2; RFC 9112 §6.3 item 1): a final response to
# HEAD, or with a 1xx, 204 or 304 status, has its status, its fields and no
# body, whatever its framing fields say
law reply_bare:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {True{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  for n: U32
  for e3: {Some{n} == Http.status.of(String.lines(before)) : Maybe<&2, U32>}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}

# LAW (RFC 9112 §4): a final head with no status code is torn
law reply_bare_none:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {True{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  for e3: {None{} == Http.status.of(String.lines(before)) : Maybe<&2, U32>}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.Torn{"the response has no status line"} : Http.Reply}

# LAW: any other final response is read as parse_response reads that head and
# the text after it
law reply_framed:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {False{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.parse.head(String.lines(before), after) : Http.Reply}

# LAW (RFC 9110 §15.2): a head is skipped exactly when it is interim and text
# follows it
law interim_skip:
  for m: Maybe<&2, U32>
  for after: String
  {Http.interim.skip(m, after)
    == Bool.and(Http.status.interim(m), Bool.not(String.is_empty(after)))
    : Bool}

# LAW (RFC 9110 §6.4.1): a 1xx, 204 or 304 status has no body
law status_empty:
  for +m: Maybe<&2, U32>
  {Http.status.empty(m)
    == Bool.or(Http.status.interim(m), Http.status.bare(m)) : Bool}

# LAW: a successful exchange's text is read by the request's method
law heard_ok:
  for +method: String
  for +text: String
  {Spec.wire.heard(method, "0\n" ++ text) == Http.parse.to(method, text)
    : Http.Reply}

# LAW: a failed exchange is torn with the reason it is reported with
law heard_fail:
  for +method: String
  for +raw: String
  for e: {False{} == Spec.wire.ok(raw) : Bool}
  {Spec.wire.heard(method, raw)
    == Http.Torn{Spec.wire.why(Spec.wire.code(raw), Spec.wire.text(raw))}
    : Http.Reply}
