# ezhttp/src/wirespec: what the client sends, when it has heard a whole
# answer, and what a failed socket call is reported as, pure. Kept apart from
# wire.bend (bend-kit-wire's effects) so the proof gate can import it.
# wire.bend and client.bend act on what is decided here.
#
# A failed exchange's answer is a non-zero status on its first line, then the
# reason (wire.fail); a successful one is the response's octets, which
# wire.bend keeps packed and packed.bend reads. SPEC.md HTTP-CLI lists what is
# guaranteed.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body
import ./pct.bend as Pct
import ./qs.bend as Qs

# --- the deadline ---

# the deadline of an exchange with no timeout: 60 s, in milliseconds
def wire.ms.dflt() -> U32:
  60000

# a timeout once it is known whether it is 0
def wire.ms.pick(ms: U32, zero: Bool) -> U32:
  match zero:
    case True{}:
      1
    case False{}:
      ms

# a timeout as a deadline bend-kit-wire reads: 0 would be none there, so it
# is 1 ms
def wire.ms.at(+ms: U32) -> U32:
  wire.ms.pick(ms, U32.is_eq(ms, 0))

# the deadline every socket call of an exchange gets: the timeout it was made
# with, or the default (SPEC.md HTTP-CLI-1, 2)
def wire.ms.of(m: Maybe<&2, U32>) -> U32:
  match m:
    case None{}:
      wire.ms.dflt()
    case Some{ms}:
      wire.ms.at(ms)

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
# ends at the blank line, and the octets go after it
def wire.exchange.octets(+method: String, l: Url.Loc,
  headers: List<&2, Http.Header>, n: Nat) -> Exchange:
  match l:
    case Url.Bad{why}:
      NoUrl{why}
    case Url.Loc{scheme, +host, +port, path}:
      +secure = String.eq(scheme, "https")
      Exchange{secure, host, port, method,
        Http.request.head.at(method, secure, host, port, path, headers, n)}

# a request with a body of this shape to a URL that came apart: text inside
# the request text as UTF-8, octets after it (SPEC.md HTTP-CLI-10)
def wire.exchange.body(method: String, l: Url.Loc,
  headers: List<&2, Http.Header>, b: Body.Shape) -> Exchange:
  match b:
    case Body.ShapeText{text}:
      wire.exchange(method, l, headers, text)
    case Body.ShapeOctets{n}:
      wire.exchange.octets(method, l, headers, U32.to_nat(n))

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

# where a response to a request with this method stands before anything has
# been received
def wire.got(+method: String) -> Http.Hear:
  Http.hear.of(method, "")

# after a read: read again from where the response now stands, or it has all
# been received
type Read is Data:
  Again{hear: Http.Hear}
  Heard{}

# where the response stands after a read, judged
def wire.read.done(+h: Http.Hear, done: Bool) -> Read:
  match done:
    case True{}:
      Heard{}
    case False{}:
      Again{h}

# where the response stands after a read, judged
def wire.read.with(+h: Http.Hear) -> Read:
  wire.read.done(h, Http.hear.done(h))

# a read that brought text, or found the connection closed
def wire.read.got(h: Http.Hear, +text: String, closed: Bool) -> Read:
  match closed:
    case True{}:
      Heard{}
    case False{}:
      wire.read.with(Http.hear.more(h, text))

# what to do after a read brought this text, judged from where the response
# stood (SPEC.md HTTP-CLI-6)
def wire.read.next(h: Http.Hear, +text: String) -> Read:
  wire.read.got(h, text, String.is_empty(text))

# a read of m octets judged by its count, when that is enough to judge it
def wire.read.counted(+h: Http.Hear, +m: Nat, counts: Bool) -> Maybe<&2, Read>:
  match counts:
    case True{}:
      Some{wire.read.with(Http.hear.more.n(h, m))}
    case False{}:
      None{}

# a read of m octets: none is the close
def wire.read.count.at(+h: Http.Hear, +m: Nat, closed: Bool)
  -> Maybe<&2, Read>:
  match closed:
    case True{}:
      Some{Heard{}}
    case False{}:
      wire.read.counted(h, m, Http.hear.counts(h, m))

# what to do after a read of m octets, when their count alone decides it;
# none when their text is needed (wire.read.next) (SPEC.md HTTP-CLI-6)
def wire.read.count(+h: Http.Hear, +m: Nat) -> Maybe<&2, Read>:
  wire.read.count.at(h, m, Nat.is_eq(m, 0n))

# the answer when the reads run out before the response ends
def wire.spent() -> String:
  "56\nthe answer did not end within 65536 reads"

# the reason a failed exchange's answer is reported with (wire.why)
def wire.failed(+raw: String) -> String:
  wire.why(wire.code(raw), wire.text(raw))

# the response an exchange's answer holds, read by the request's method
# (SPEC.md HTTP-CLI-9); a failed exchange is torn with the reason it is
# reported with (wire.why)
def wire.heard.of(+method: String, +raw: String, ok: Bool) -> Http.Reply:
  match ok:
    case False{}:
      Http.Torn{wire.failed(raw)}
    case True{}:
      Http.parse.to(method, wire.text(raw))

# the reason phrase of the response an exchange's answer holds (SPEC.md
# HTTP-CLI-11); a failed exchange's is read from its reason and not used
def wire.phrase(raw: String) -> String:
  Http.phrase.to(wire.text(raw))

# the response an exchange's answer holds
def wire.heard(+method: String, +raw: String) -> Http.Reply:
  wire.heard.of(method, raw, wire.ok(raw))

# --- what goes on the wire (SPEC.md HTTP-CLI-10) ---

# a request text's UTF-8 octets, one character each, onto the octets after it
def wire.payload.text(s: String, rest: String) -> String:
  match s:
    case SNil{}:
      rest
    case SCon{Chr{+cp}, t}:
      Body.octets.chars(Pct.utf8(cp)) ++ wire.payload.text(t, rest)

# the octets of a request text, one character each: its UTF-8 (the body's
# octets go after them)
def wire.payload(req: String) -> String:
  wire.payload.text(req, "")

# --- what a failed socket call is reported as (SPEC.md HTTP-CLI-13, 14) ---

# where in an exchange a call failed
type Phase is Data:
  Resolve{}
  Connect{}
  Handshake{}
  Send{}
  Receive{}

# the error number a call that ran out of time fails with (Linux ETIMEDOUT)
def wire.etimedout() -> U32:
  110

# the Linux errno symbols this table names
def wire.errnos() -> List<&2, Http.Phrase>:
  [Http.P{1, "EPERM"}, Http.P{2, "ENOENT"}, Http.P{4, "EINTR"},
    Http.P{5, "EIO"}, Http.P{9, "EBADF"}, Http.P{11, "EAGAIN"},
    Http.P{12, "ENOMEM"}, Http.P{13, "EACCES"}, Http.P{22, "EINVAL"},
    Http.P{23, "ENFILE"}, Http.P{24, "EMFILE"}, Http.P{32, "EPIPE"},
    Http.P{71, "EPROTO"}, Http.P{88, "ENOTSOCK"},
    Http.P{93, "EPROTONOSUPPORT"}, Http.P{97, "EAFNOSUPPORT"},
    Http.P{98, "EADDRINUSE"}, Http.P{99, "EADDRNOTAVAIL"},
    Http.P{100, "ENETDOWN"}, Http.P{101, "ENETUNREACH"},
    Http.P{103, "ECONNABORTED"}, Http.P{104, "ECONNRESET"},
    Http.P{105, "ENOBUFS"}, Http.P{106, "EISCONN"},
    Http.P{107, "ENOTCONN"}, Http.P{110, "ETIMEDOUT"},
    Http.P{111, "ECONNREFUSED"}, Http.P{112, "EHOSTDOWN"},
    Http.P{113, "EHOSTUNREACH"}, Http.P{114, "EALREADY"},
    Http.P{115, "EINPROGRESS"}]

# a name from the table, or `errno` when it has none
def wire.errno.or(name: String) -> String:
  match name:
    case SNil{}:
      "errno"
    case SCon{h, t}:
      SCon{h, t}

# an error number's name (SPEC.md HTTP-CLI-14)
def wire.errno.name(+n: U32) -> String:
  wire.errno.or(Http.reason.in(wire.errnos(), n))

# an error number as a reason names it: `<name> (<n>)`
def wire.cause(+n: U32) -> String:
  wire.errno.name(n) ++ " (" ++ U32.show(n) ++ ")"

# a resolve's failure: bend-kit-dns reports a name with no address as
# ENOENT, whose name would read as a missing file, so only the host is named
def wire.fail.resolve(host: String, +n: U32, none: Bool) -> String:
  match none:
    case True{}:
      "6\ncould not resolve " ++ host
    case False{}:
      "6\ncould not resolve " ++ host ++ ": " ++ wire.cause(n)

# a call that ran out of time, by its phase
def wire.fail.late(p: Phase, host: String, +port: U32, +ms: U32, +n: U32)
  -> String:
  match p:
    case Resolve{}:
      wire.fail.resolve(host, n, U32.is_eq(n, 2))
    case Connect{}:
      "28\nconnecting to " ++ host ++ " port " ++ U32.show(port)
        ++ " took over " ++ U32.show(ms) ++ " ms"
    case Handshake{}:
      "28\nthe TLS handshake with " ++ host ++ " took over " ++ U32.show(ms)
        ++ " ms"
    case Send{}:
      "28\nsending the request to " ++ host ++ " took over " ++ U32.show(ms)
        ++ " ms"
    case Receive{}:
      "28\n" ++ host ++ " sent nothing for " ++ U32.show(ms) ++ " ms"

# a call that failed for another reason, by its phase
def wire.fail.other(p: Phase, host: String, +port: U32, +n: U32, why: String)
  -> String:
  match p:
    case Resolve{}:
      wire.fail.resolve(host, n, U32.is_eq(n, 2))
    case Connect{}:
      "7\ncould not reach " ++ host ++ " port " ++ U32.show(port) ++ ": "
        ++ wire.cause(n)
    case Handshake{}:
      "35\nthe TLS handshake with " ++ host ++ " failed: " ++ wire.cause(n)
        ++ ": " ++ why
    case Send{}:
      "55\nthe request to " ++ host ++ " could not be sent: " ++ wire.cause(n)
    case Receive{}:
      "56\nthe answer from " ++ host ++ " was cut short: " ++ wire.cause(n)

# a failure once it is known whether it ran out of time
def wire.fail.of(p: Phase, host: String, +port: U32, +ms: U32, +n: U32,
  why: String, late: Bool) -> String:
  match late:
    case True{}:
      wire.fail.late(p, host, port, ms, n)
    case False{}:
      wire.fail.other(p, host, port, n, why)

# the exchange's answer when a call in this phase failed with error number n
# and reason why, with deadline ms (SPEC.md HTTP-CLI-13)
def wire.fail(p: Phase, host: String, +port: U32, +ms: U32, +n: U32,
  why: String) -> String:
  wire.fail.of(p, host, port, ms, n, why, U32.is_eq(n, wire.etimedout()))
