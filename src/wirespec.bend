# ezhttp/src/wirespec: what the client sends, when it has heard a whole
# answer, and what a failed socket call is reported as, pure. Kept apart from
# wire.bend (bend-kit-wire's effects) so the proof gate can import it.
# wire.bend and client.bend act on what is decided here.
#
# An exchange's answer is a status on its first line, then text: "0" and the
# response received, or a non-zero status and the reason the exchange failed.
# SPEC.md HTTP-CLI lists what is guaranteed.
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

# --- what goes on the wire (SPEC.md HTTP-CLI-10) ---

# a request text's UTF-8 octets, one character each, onto the octets after it
def wire.payload.text(s: String, rest: String) -> String:
  match s:
    case SNil{}:
      rest
    case SCon{Chr{+cp}, t}:
      Body.octets.chars(Pct.utf8(cp)) ++ wire.payload.text(t, rest)

# the octets an exchange sends, one character each: the request text as
# UTF-8, then the body's tail
def wire.payload(req: String, tail: List<&2, U32>) -> String:
  wire.payload.text(req, Body.octets.chars(tail))

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

# a call that ran out of time, by its phase
def wire.fail.late(p: Phase, host: String, +port: U32, +ms: U32, +n: U32)
  -> String:
  match p:
    case Resolve{}:
      "6\ncould not resolve " ++ host ++ ": " ++ wire.cause(n)
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
      "6\ncould not resolve " ++ host ++ ": " ++ wire.cause(n)
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

# --- received octets as text (SPEC.md HTTP-TRUST-5) ---

# how many continuation octets a lead octet asks for (RFC 3629 §3); 0 for an
# octet that opens no sequence
def wire.utf8.wants(+b: U32) -> Nat:
  Bool.pick(Nat, U32.is_lt(b, 194), 0n,
    Bool.pick(Nat, U32.is_lt(b, 224), 1n,
      Bool.pick(Nat, U32.is_lt(b, 240), 2n,
        Bool.pick(Nat, U32.is_lt(b, 245), 3n, 0n))))

# whether an octet continues a sequence (10xxxxxx)
def wire.utf8.cont(+b: U32) -> Bool:
  Bool.and(U32.is_le(128, b), U32.is_lt(b, 192))

# the octet before k continuation octets: hold the k + 1 when it opens a
# sequence that wants more than k
def wire.utf8.lead(+b: U32, +k: Nat) -> Nat:
  Bool.pick(Nat, Nat.is_lt(k, wire.utf8.wants(b)), 1n+k, 0n)

# one octet from the end: another continuation octet, or the one before them
def wire.utf8.back(+b: U32, +k: Nat, more: Bool, rest: Unit -> Nat) -> Nat:
  match more:
    case True{}:
      rest(Unit{})
    case False{}:
      wire.utf8.lead(b, k)

# how many octets at the end of a list, given newest first, are a sequence
# still waiting for octets; k continuation octets have been passed
def wire.utf8.open(r: List<&2, U32>, +k: Nat) -> Nat:
  match r:
    case []:
      0n
    case +b <> t:
      wire.utf8.back(b, k, Bool.and(wire.utf8.cont(b), Nat.is_lt(k, 3n)),
        _u => wire.utf8.open(t, 1n+k))

# octets as the pieces Qs.utf.dec reads
def wire.utf8.toks(bs: List<&2, U32>) -> List<&2, Qs.Tok>:
  match bs:
    case []:
      []
    case b <> t:
      Qs.B{b} <> wire.utf8.toks(t)

# octets, one character each, as a list
def wire.utf8.bytes(s: String) -> List<&2, U32>:
  match s:
    case SNil{}:
      []
    case SCon{c, t}:
      Char.to_u32(c) <> wire.utf8.bytes(t)

# the octets held from before and a receive's octets: the text of all but a
# sequence still open at the end, and that sequence, held for the next
def wire.utf8.feed(held: List<&2, U32>, got: String)
  -> String & List<&2, U32>:
  +bs = List.append(&2, U32, held, wire.utf8.bytes(got))
  +n = List.length(&2, U32, bs)
  +m = wire.utf8.open(List.reverse(&2, U32, bs), 0n)
  +k = Nat.sub(n, m)
  (Qs.utf.dec(wire.utf8.toks(List.take(&2, U32, bs, k)), Qs.Idle{}),
    List.drop(&2, U32, bs, k))

# what was held once the server has closed: decoded as it is
def wire.utf8.flush(held: List<&2, U32>) -> String:
  Qs.utf.dec(wire.utf8.toks(held), Qs.Idle{})
