# ezhttp/src/wirespec: the text the wire effect reads, and what its answer
# means, pure. Kept apart from wire.bend (the effect) so the proof gate can
# import it. What the client sends for a URL (wire.exchange) and when it has
# heard a whole answer (wire.read.next) are decided here; wire.bend and
# client.bend act on them.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim. The scheme line may carry a timeout after a
# space: 32 binary digits, least significant first, in milliseconds. A scheme
# line with no timeout means 60000 ms. SPEC.md HTTP-CLI lists what is
# guaranteed.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body

# the word the effect reads for a scheme that wants TLS
def wire.scheme(secure: Bool) -> String:
  match secure:
    case True{}:
      "tls"
    case False{}:
      "tcp"

# the spec the effect reads
def wire.spec(secure: Bool, host: String, port: U32, req: String) -> String:
  wire.scheme(secure) ++ "\n" ++ host ++ "\n" ++ U32.show(port) ++ "\n" ++ req

# --- the timeout ---

# the timeout a spec with none carries: 60 s, in milliseconds
def wire.ms.dflt() -> U32:
  60000

# one bit as a binary digit
def wire.bit(b: Bool) -> Char:
  match b:
    case True{}:
      '1'
    case False{}:
      '0'

# a word as binary digits, least significant first
def wire.bits(n: Nat, w: Word(n)) -> String:
  match n:
    case 0n:
      SNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          SCon{wire.bit(b), wire.bits(p, t)}

# binary digits, least significant first, as a word; a missing digit is 0
def wire.bits.read(n: Nat, s: String) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match s:
        case SNil{}:
          WCon{False{}, wire.bits.read(p, SNil{})}
        case SCon{c, t}:
          WCon{Char.is_eq(c, '1'), wire.bits.read(p, t)}

# a timeout as the scheme line carries it
def wire.ms.text(ms: U32) -> String:
  match ms:
    case U32{w}:
      wire.bits(32n, w)

# the first line of a timed spec: the scheme, a space, the timeout
def wire.head(secure: Bool, ms: U32) -> String:
  wire.scheme(secure) ++ " " ++ wire.ms.text(ms)

# the lines after the first: host, port, then the request verbatim
def wire.rest(host: String, port: U32, req: String) -> String:
  host ++ "\n" ++ U32.show(port) ++ "\n" ++ req

# the spec the effect reads, with a timeout in milliseconds
def wire.spec.timed(secure: Bool, ms: U32, host: String, port: U32,
  req: String) -> String:
  wire.head(secure, ms) ++ "\n" ++ wire.rest(host, port, req)

# the timeout after the scheme word, or the default when there is none
def wire.ms.words(ws: List<&2, String>) -> U32:
  match ws:
    case []:
      wire.ms.dflt()
    case _ <> []:
      wire.ms.dflt()
    case _ <> (bits <> _):
      U32{wire.bits.read(32n, bits)}

# the first line of a spec
def wire.line(ls: List<&2, String>) -> String:
  match ls:
    case []:
      ""
    case l <> _:
      l

# the timeout the effect reads from a spec, in milliseconds
def wire.ms(spec: String) -> U32:
  wire.ms.words(String.split(wire.line(String.split(spec, '\n')), ' '))

# --- the answer ---

# the wire status for an exchange that ran out of time (curl's
# CURLE_OPERATION_TIMEDOUT)
def wire.late() -> U32:
  28

# what a failed exchange is reported as: a timeout is marked, any other
# failure's reason is kept as it is
def wire.why.of(why: String, late: Bool) -> String:
  match late:
    case True{}:
      "timed out: " ++ why
    case False{}:
      why

# a failed exchange's status and reason as the reason the client reports
def wire.why(code: Maybe<&2, U32>, why: String) -> String:
  match code:
    case None{}:
      why
    case Some{n}:
      wire.why.of(why, U32.is_eq(n, wire.late()))

# whether a reported reason is a timeout
def wire.timed_out(why: String) -> Bool:
  String.starts_with(why, "timed out: ")

# --- what is sent ---

# what a request to a URL becomes: nothing when the URL did not parse, else
# the scheme (secure or not), host, port, method and request text the effect
# is given; the answer is read by that method (wire.read.next)
type Exchange is Data:
  NoUrl{why: String}
  Exchange{secure: Bool, host: String, port: U32, method: String, req: String}

# the exchange once it is known whether the scheme wants TLS
def wire.exchange.at(+method: String, +secure: Bool, +host: String,
  +port: U32, path: String, headers: List<&2, Http.Header>, body: String)
  -> Exchange:
  Exchange{secure, host, port, method,
    Http.request.at(method, secure, host, port, path, headers, body)}

# the method an exchange is sent and read by, none when nothing is sent
def wire.exchange.method(ex: Exchange) -> Maybe<&2, String>:
  match ex:
    case NoUrl{why}:
      None{}
    case Exchange{secure, host, port, method, req}:
      Some{method}

# a request with this method, headers and body to a URL that came apart
def wire.exchange(method: String, l: Url.Loc, headers: List<&2, Http.Header>,
  body: String) -> Exchange:
  match l:
    case Url.Bad{why}:
      NoUrl{why}
    case Url.Loc{scheme, host, port, path}:
      +secure = String.eq(scheme, "https")
      wire.exchange.at(method, secure, host, port, path, headers, body)

# a request with n octets of body to a URL that came apart: the request text
# ends at the blank line, and the octets go after it as the tail (wire.tail)
def wire.exchange.octets(+method: String, l: Url.Loc,
  headers: List<&2, Http.Header>, n: Nat) -> Exchange:
  match l:
    case Url.Bad{why}:
      NoUrl{why}
    case Url.Loc{scheme, +host, +port, path}:
      +secure = String.eq(scheme, "https")
      Exchange{secure, host, port, method,
        Http.request.head.at(method, secure, host, port, path, headers, n)}

# a request with this body to a URL that came apart: text inside the request
# text as UTF-8, octets after it (SPEC.md HTTP-CLI-10)
def wire.exchange.body(method: String, l: Url.Loc,
  headers: List<&2, Http.Header>, b: Body.Body) -> Exchange:
  match b:
    case Body.Empty{}:
      wire.exchange(method, l, headers, "")
    case Body.Plain{text}:
      wire.exchange(method, l, headers, text)
    case Body.Octets{bytes}:
      wire.exchange.octets(method, l, headers, List.length(&2, U32, bytes))

# the octets sent after the request text: an octet body's, else none
def wire.tail(b: Body.Body) -> List<&2, U32>:
  match b:
    case Body.Empty{}:
      []
    case Body.Plain{text}:
      []
    case Body.Octets{bytes}:
      bytes

# --- what is heard ---

# an answer's status: the number on its first line, if it is one
def wire.code.of(c: Http.Cut, raw: String) -> Maybe<&2, U32>:
  match c:
    case Http.NoCut{}:
      U32.read(raw)
    case Http.Cut{before, after}:
      U32.read(before)

# an answer's status line as a number
def wire.code(+raw: String) -> Maybe<&2, U32>:
  wire.code.of(Http.divide(raw, "\n"), raw)

# the text after an answer's first newline
def wire.text.of(c: Http.Cut) -> String:
  match c:
    case Http.NoCut{}:
      ""
    case Http.Cut{before, after}:
      after

# the text after an answer's first newline
def wire.text(raw: String) -> String:
  wire.text.of(Http.divide(raw, "\n"))

# whether a status is success (0)
def wire.ok.of(m: Maybe<&2, U32>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{n}:
      U32.is_eq(n, 0)

# whether an answer has status 0
def wire.ok(raw: String) -> Bool:
  wire.ok.of(wire.code(raw))

# what an open answered: a connection to read from, or the answer itself
type Opened is Data:
  Refused{answer: String}
  Open{conn: U32}

# a connection number that read, or a malformed answer when it did not
def wire.opened.conn(m: Maybe<&2, U32>) -> Opened:
  match m:
    case None{}:
      Refused{"22\na malformed connection number"}
    case Some{n}:
      Open{n}

# an open's answer once it is known whether it succeeded
def wire.opened.of(+got: String, ok: Bool) -> Opened:
  match ok:
    case False{}:
      Refused{got}
    case True{}:
      wire.opened.conn(U32.read(wire.text(got)))

# what an open's answer means
def wire.opened(+got: String) -> Opened:
  wire.opened.of(got, wire.ok(got))

# what has been received so far: its pieces, the newest first, and where
# the response stands (Http.hear)
type Got is Data:
  Got{pieces: List<&2, String>, hear: Http.Hear}

# the text a list of pieces, newest first, stands for
def wire.joined(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case p <> rest:
      wire.joined(rest) ++ p

# the pieces put together onto what follows them, each copied once
def wire.join.go(ps: List<&2, String>, acc: String) -> String:
  match ps:
    case []:
      acc
    case p <> rest:
      wire.join.go(rest, p ++ acc)

# the text a list of pieces, newest first, stands for, built in one pass
def wire.join(ps: List<&2, String>) -> String:
  wire.join.go(ps, "")

# what has been received as these pieces, for a request with this method
def wire.got(+method: String, +ps: List<&2, String>) -> Got:
  Got{ps, Http.hear.of(method, wire.joined(ps))}

# after a read: read again with what has arrived, or answer
type Read is Data:
  Again{acc: Got}
  Heard{answer: String}

# everything received, once it is known whether it is a whole response
def wire.read.whole(+ps: List<&2, String>, h: Http.Hear, done: Bool) -> Read:
  match done:
    case True{}:
      Heard{"0\n" ++ wire.join(ps)}
    case False{}:
      Again{Got{ps, h}}

# a read that brought text, judged with where the response now stands
def wire.read.add(text: String, ps: List<&2, String>, +h: Http.Hear) -> Read:
  wire.read.whole(text <> ps, h, Http.hear.done(h))

# a read that brought text, or found the connection closed
def wire.read.got(st: Got, +text: String, closed: Bool) -> Read:
  match st closed:
    case Got{ps, h} True{}:
      Heard{"0\n" ++ wire.join(ps)}
    case Got{ps, h} False{}:
      wire.read.add(text, ps, Http.hear.more(h, text))

# a read's answer once it is known whether it succeeded
def wire.read.of(st: Got, +got: String, ok: Bool) -> Read:
  match ok:
    case False{}:
      Heard{got}
    case True{}:
      +text = wire.text(got)
      wire.read.got(st, text, String.is_empty(text))

# what to do after a read answered `got`, with what was received before it
# (SPEC.md HTTP-CLI-6)
def wire.read.next(st: Got, +got: String) -> Read:
  wire.read.of(st, got, wire.ok(got))

# the answer when the reads run out before the response ends
def wire.spent() -> String:
  "56\nthe answer did not end within 65536 reads"

# the response an exchange's answer holds, read by the request's method
# (SPEC.md HTTP-CLI-9); a failed exchange is torn with the reason it is
# reported with (wire.why)
def wire.heard.of(+method: String, +raw: String, ok: Bool) -> Http.Reply:
  match ok:
    case False{}:
      Http.Torn{wire.why(wire.code(raw), wire.text(raw))}
    case True{}:
      Http.parse.to(method, wire.text(raw))

# the reason phrase of the response an exchange's answer holds (SPEC.md
# HTTP-CLI-11); a failed exchange's is read from its reason and not used
def wire.phrase(raw: String) -> String:
  Http.phrase.to(wire.text(raw))

# the response an exchange's answer holds
def wire.heard(+method: String, +raw: String) -> Http.Reply:
  wire.heard.of(method, raw, wire.ok(raw))
