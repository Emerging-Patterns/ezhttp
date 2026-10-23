# ezhttp/src/wire: one request out and one response back, over
# bend-kit-wire's sockets. Its effects park on the runtime's event loop, so
# exchanges run side by side under IO.fork. bend-kit-dns resolves the host;
# TLS is bend-kit-wire's (OpenSSL 3 loaded at run time, BEND_LIBSSL to point
# at it).
#
# An exchange's answer is every octet of the response, packed (Received), or
# a failure: a non-zero status on its first line, then the reason
# (wirespec.bend wire.fail). Every decision is wirespec.bend's: the deadline
# (wire.ms.of), the octets sent (wire.payload), what a failed call is reported
# as (wire.fail) and when the response is whole (wire.read.count, else
# wire.read.next on a copy of the receive as text), so a server that keeps the
# connection open after a complete response is not waited on (SPEC.md
# HTTP-CLI-1, 6, 10, 13; HTTP-TRUST-3, 5).
import Base
import bend-kit-wire@0.4.6.1/wire.bend as W
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import bend-kit-dns@0.6.0.2/dns.bend as Dns
import ./wirespec.bend as Spec
import ./http.bend as Http

# the most octets one receive asks for
def wire.max() -> U32:
  65536

# the most receives one exchange makes
def wire.reads() -> Nat:
  65536n

# --- the socket calls, plain or over TLS ---

# close a socket, ending its TLS session when it has one
def wire.close(secure: Bool, s: Socket) -> IO(Unit):
  match secure:
    case True{}:
      W.tls.close(s)
    case False{}:
      Socket.close(s)

# the next octets a socket has received, packed four to a word
def wire.recv(secure: Bool, s: Socket, ms: U32)
  -> IO(Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>):
  match secure:
    case True{}:
      W.tls.recv.words(s, wire.max(), ms)
    case False{}:
      W.recv.words(s, wire.max(), ms)

# a send.words.deadline answer without its count of octets accepted
def wire.sent(r: Socket & (U32 & Result<&1, &1, U32 & String, Unit>))
  -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
  (s, (n, res)) = r
  IO.pure(Socket & Result<&1, &1, U32 & String, Unit>, (s, res))

# send octets, the plain send bounded by the deadline
def wire.send(secure: Bool, s: Socket, +len: U32, buf: Array<U32>, ms: U32)
  -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
  match secure:
    case True{}:
      W.tls.send.words(s, len, buf)
    case False{}:
      IO.bind(Socket & (U32 & Result<&1, &1, U32 & String, Unit>),
        Socket & Result<&1, &1, U32 & String, Unit>,
        W.send.words.deadline(s, len, buf, ms), wire.sent)

# the TLS handshake with the host, when the exchange is secure
def wire.shake(secure: Bool, s: Socket, host: String, ms: U32)
  -> IO(Socket & Result<&1, &1, U32 & String, Unit>):
  match secure:
    case True{}:
      W.tls.connect(s, host, ms)
    case False{}:
      IO.pure(Socket & Result<&1, &1, U32 & String, Unit>, (s, Done{Unit{}}))

# --- reading the answer ---

# an exchange's answer: the failure it was reported with (a status other than
# 0 on its first line, then the reason, wirespec.bend wire.fail), or every
# octet of the response, packed
type Answer is Type:  # noqa: L001 holds packed Bytes, which no law reaches (HTTP-TRUST-5)
  Failed{answer: String}
  Received{octets: Bytes.Bytes}

# a failed call's answer, the socket closed first
def wire.failed(+secure: Bool, s: Socket, answer: String) -> IO(Answer):
  IO.bind(Unit, Answer, wire.close(secure, s),
    _u => IO.pure(Answer, Failed{answer}))

# a judged read: read again, or close and answer what was received
def wire.loop.on(+secure: Bool, s: Socket, r: Spec.Read, acc: Bytes.Bytes,
  more: Socket -> Http.Hear -> Bytes.Bytes -> IO(Answer)) -> IO(Answer):
  match r:
    case Spec.Again{h}:
      more(s)(h)(acc)
    case Spec.Heard{}:
      IO.bind(Unit, Answer, wire.close(secure, s),
        _u => IO.pure(Answer, Received{acc}))

# a receive judged by a copy of it as text, dropped after the judging; the
# octets themselves are appended packed
def wire.loop.copied(+secure: Bool, s: Socket, h: Http.Hear,
  r: Bytes.Bytes & Bytes.Bytes, acc: Bytes.Bytes,
  more: Socket -> Http.Hear -> Bytes.Bytes -> IO(Answer)) -> IO(Answer):
  (kept, copy) = r
  wire.loop.on(secure, s, Spec.wire.read.next(h, Bytes.to_string(copy)),
    Bytes.append(acc, kept), more)

# a read judged by its text, when its count alone does not decide it
def wire.loop.text(+secure: Bool, s: Socket, h: Http.Hear, piece: Bytes.Bytes,
  acc: Bytes.Bytes, more: Socket -> Http.Hear -> Bytes.Bytes -> IO(Answer))
  -> IO(Answer):
  wire.loop.copied(secure, s, h, Bytes.slice(piece, 0, 4294967295), acc, more)

# a read judged by its count when that decides it (SPEC.md HTTP-CLI-6)
def wire.loop.judge(+secure: Bool, s: Socket, h: Http.Hear, piece: Bytes.Bytes,
  acc: Bytes.Bytes, counted: Maybe<&2, Spec.Read>,
  more: Socket -> Http.Hear -> Bytes.Bytes -> IO(Answer)) -> IO(Answer):
  match counted:
    case Some{r}:
      wire.loop.on(secure, s, r, Bytes.append(acc, piece), more)
    case None{}:
      wire.loop.text(secure, s, h, piece, acc, more)

# a receive's outcome: a failure is the answer
def wire.loop.un(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +h: Http.Hear, acc: Bytes.Bytes,
  r: Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>,
  more: Socket -> Http.Hear -> Bytes.Bytes -> IO(Answer)) -> IO(Answer):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      wire.failed(secure, s,
        Spec.wire.fail(Spec.Receive{}, host, port, ms, n, why))
    case Done{(+len, buf)}:
      wire.loop.judge(secure, s, h, Bytes.Bytes{len, buf}, acc,
        Spec.wire.read.count(h, U32.to_nat(len)), more)

# receive until wirespec.bend says the answer is whole, the octets appended
# to what came before
def wire.loop(fuel: Nat, +secure: Bool, s: Socket, +host: String, +port: U32,
  +ms: U32, h: Http.Hear, acc: Bytes.Bytes) -> IO(Answer):
  match fuel:
    case 0n:
      wire.failed(secure, s, Spec.wire.spent())
    case 1n+p:
      IO.bind(Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>, Answer,
        wire.recv(secure, s, ms),
        r => wire.loop.un(secure, host, port, ms, h, acc, r,
          s2 => h2 => a2 => wire.loop(p, secure, s2, host, port, ms, h2, a2)))

# --- one exchange ---

# after the send: read the answer, or the send's failure
def wire.after.send(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, r: Socket & Result<&1, &1, U32 & String, Unit>)
  -> IO(Answer):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      wire.failed(secure, s,
        Spec.wire.fail(Spec.Send{}, host, port, ms, n, why))
    case Done{_u}:
      wire.loop(wire.reads(), secure, s, host, port, ms, Spec.wire.got(method),
        Bytes.new(0))

# send the octets an exchange carries, then read its answer
def wire.put(+secure: Bool, s: Socket, +host: String, +port: U32, +ms: U32,
  +method: String, payload: Bytes.Bytes) -> IO(Answer):
  Bytes.Bytes{+len, buf} = payload
  IO.bind(Socket & Result<&1, &1, U32 & String, Unit>, Answer,
    wire.send(secure, s, len, buf, ms),
    r => wire.after.send(secure, host, port, ms, method, r))

# after the handshake: send, or the handshake's failure (the socket closed
# plainly, as no TLS session was made)
def wire.after.shake(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, payload: Bytes.Bytes,
  r: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Answer):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      IO.bind(Unit, Answer, Socket.close(s),
        _u => IO.pure(Answer,
          Failed{Spec.wire.fail(Spec.Handshake{}, host, port, ms, n, why)}))
    case Done{_u}:
      wire.put(secure, s, host, port, ms, method, payload)

# after the connect: the handshake, or the connect's failure
def wire.after.connect(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, payload: Bytes.Bytes,
  r: Result<&1, &1, U32 & String, Socket>) -> IO(Answer):
  match r:
    case Fail{(n, why)}:
      IO.pure(Answer,
        Failed{Spec.wire.fail(Spec.Connect{}, host, port, ms, n, why)})
    case Done{s}:
      IO.bind(Socket & Result<&1, &1, U32 & String, Unit>, Answer,
        wire.shake(secure, s, host, ms),
        r2 => wire.after.shake(secure, host, port, ms, method, payload, r2))

# a connect that failed tries the next address; one that worked is kept
def wire.dial.next(r: Result<&1, &1, U32 & String, Socket>,
  more: Unit -> IO(Result<&1, &1, U32 & String, Socket>))
  -> IO(Result<&1, &1, U32 & String, Socket>):
  match r:
    case Done{s}:
      IO.pure(Result<&1, &1, U32 & String, Socket>, Done{s})
    case Fail{e}:
      more(Unit{})

# connect to each address in turn until one connects; the last one's
# failure when none does
def wire.dial(rest: List<&2, String>, +first: String, +port: U32, +ms: U32)
  -> IO(Result<&1, &1, U32 & String, Socket>):
  match rest:
    case []:
      W.connect(first, port, ms)
    case ip <> t:
      IO.bind(Result<&1, &1, U32 & String, Socket>,
        Result<&1, &1, U32 & String, Socket>,
        W.connect(first, port, ms),
        r => wire.dial.next(r, _u => wire.dial(t, ip, port, ms)))

# after the resolve: connect, or the resolve's failure (no address at all is
# ENOENT, as bend-kit-dns reports a name with none)
def wire.after.resolve(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, payload: Bytes.Bytes,
  r: Result<&1, &1, U32 & String, List<&2, String>>) -> IO(Answer):
  match r:
    case Fail{(n, why)}:
      IO.pure(Answer,
        Failed{Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why)})
    case Done{[]}:
      IO.pure(Answer,
        Failed{Spec.wire.fail(Spec.Resolve{}, host, port, ms, 2, "")})
    case Done{ip <> t}:
      IO.bind(Result<&1, &1, U32 & String, Socket>, Answer,
        wire.dial(t, ip, port, ms),
        c => wire.after.connect(secure, host, port, ms, method, payload, c))

# the OS resolver's addresses, NUL-separated, as a list
def wire.looked(r: Result<&1, &1, U32 & String, String>)
  -> IO(Result<&1, &1, U32 & String, List<&2, String>>):
  match r:
    case Fail{e}:
      IO.pure(Result<&1, &1, U32 & String, List<&2, String>>, Fail{e})
    case Done{text}:
      IO.pure(Result<&1, &1, U32 & String, List<&2, String>>,
        Done{Dns.lookup.split(text)})

# a host's addresses: a numeric address or localhost as it is, else the OS
# resolver's answer
def wire.resolve(+host: String, literal: List<&2, String>)
  -> IO(Result<&1, &1, U32 & String, List<&2, String>>):
  match literal:
    case []:
      IO.bind(Result<&1, &1, U32 & String, String>,
        Result<&1, &1, U32 & String, List<&2, String>>,
        Dns.lookup.all(String.to_lower(host)), wire.looked)
    case ip <> t:
      IO.pure(Result<&1, &1, U32 & String, List<&2, String>>, Done{ip <> t})

# the exchange once its octets are packed
def wire.run.with(+secure: Bool, +ms: U32, +host: String, +port: U32,
  +method: String, payload: Bytes.Bytes) -> IO(Answer):
  IO.bind(Result<&1, &1, U32 & String, List<&2, String>>, Answer,
    wire.resolve(host, Dns.resolve.literal.all(host)),
    r => wire.after.resolve(secure, host, port, ms, method, payload, r))

# a request with this method, sent to a host as wirespec.bend says, with
# its tail of octets after it, every call bounded by the deadline; its whole
# answer
def wire.run(+secure: Bool, +ms: U32, +host: String, +port: U32,
  +method: String, req: String, tail: Bytes.Bytes) -> IO(Answer):
  wire.run.with(secure, ms, host, port, method,
    Bytes.append(Bytes.from_string(Spec.wire.payload(req)), tail))

# a request sent to a host, its tail of octets after it, and its whole answer
# read back, with the default deadline
def wire.talk(secure: Bool, host: String, port: U32, method: String,
  req: String, tail: Bytes.Bytes) -> IO(Answer):
  wire.run(secure, Spec.wire.ms.of(None{}), host, port, method, req, tail)

# the same exchange, bounded by a timeout in milliseconds
def wire.talk.timed(secure: Bool, ms: U32, host: String, port: U32,
  method: String, req: String, tail: Bytes.Bytes) -> IO(Answer):
  wire.run(secure, Spec.wire.ms.of(Some{ms}), host, port, method, req, tail)
