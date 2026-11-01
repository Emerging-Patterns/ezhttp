# For every text an exchange answers with, the response's reason phrase
# (`Client.Response`'s `reason`, and `reason_phrase(raw)` on a response's
# text) is read from the status line of the head
# laws/InterimResponsesSkipped.bend stops at, an interim head with text
# after it skipped by the same rule (RFC 9110 §15.2), and is empty when no
# head ends. RFC 9112 §4 writes a status line as `HTTP-version SP
# status-code SP [ reason-phrase ]`, and a reason-phrase holds no CR, so for
# every version `v` and code `c` that hold no SP and every reason `r` that
# holds no CR, the line `<v> <c> <r>` has reason exactly `r`, also when it
# still ends in the CR of its CRLF; a line with one SP or none has an empty
# reason.
import Base
import ../src/http.bend as Http
import ../src/wirespec.bend as Spec
import ./defs/CharacterAbsent.bend as D1

# --- a response's reason phrase ---

# LAW: a text's reason phrase is read head by head, at most as many heads as
# it has characters
law phrase_to:
  for +raw: String
  {Http.phrase.to(raw)
    == Http.phrase.to.go(String.length(raw), Http.divide(raw, "\r\n\r\n"))
    : String}

# LAW: a read with no heads left found no reason
law phrase_fuel:
  for c: Http.Cut
  {Http.phrase.to.go(0n, c) == "" : String}

# LAW (RFC 9112 §2.1): a head that never ends has no reason
law phrase_open:
  for f: Nat
  {Http.phrase.to.go(1n+f, Http.NoCut{}) == "" : String}

# LAW (RFC 9110 §15.2): an interim head with text after it is skipped by the
# same rule laws/InterimResponsesSkipped.bend skips it by, and the reason
# read from the text after it
law phrase_interim:
  for f: Nat
  for +before: String
  for +after: String
  for e: {True{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.phrase.to.go(1n+f, Http.Cut{before, after})
    == Http.phrase.to.go(f, Http.divide(after, "\r\n\r\n")) : String}

# LAW: the head laws/InterimResponsesSkipped.bend stops at gives the reason
# on its status line
law phrase_final:
  for f: Nat
  for +before: String
  for +after: String
  for e: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.phrase.to.go(1n+f, Http.Cut{before, after})
    == Http.phrase.line(Http.first(String.lines(before))) : String}

# LAW (RFC 9112 §4): a status line `<v> SP <c> SP <r>` whose version and code
# hold no SP and whose reason holds no CR has reason exactly r
law phrase_line:
  for +v: String
  for +c: String
  for +r: String
  for e1: {True{} == D1.avoids(v, ' ') : Bool}
  for e2: {True{} == D1.avoids(c, ' ') : Bool}
  for e3: {True{} == D1.avoids(r, '\r') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c ++ SCon{' ', r}}) == r : String}

# LAW (RFC 9112 §4): the CR that ends a status line's CRLF is not part of
# its reason
law phrase_line_cr:
  for +v: String
  for +c: String
  for +r: String
  for e1: {True{} == D1.avoids(v, ' ') : Bool}
  for e2: {True{} == D1.avoids(c, ' ') : Bool}
  for e3: {True{} == D1.avoids(r, '\r') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c ++ SCon{' ', r ++ "\r"}}) == r : String}

# LAW: a status line with one SP has an empty reason
law phrase_line_one:
  for +v: String
  for +c: String
  for e1: {True{} == D1.avoids(v, ' ') : Bool}
  for e2: {True{} == D1.avoids(c, ' ') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c}) == "" : String}

# LAW: a status line with no SP has an empty reason
law phrase_line_none:
  for +v: String
  for e: {True{} == D1.avoids(v, ' ') : Bool}
  {Http.phrase.line(v) == "" : String}

# LAW: the client reads the reason from the same text it reads the response
# from
law phrase_heard:
  for +text: String
  {Spec.wire.phrase("0\n" ++ text) == Http.phrase.to(text) : String}
