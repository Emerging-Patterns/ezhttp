# ezhttp/src/wire: one request out and one response back, over
# bend-kit-wire's sockets. Its effects park on the runtime's event loop, so
# exchanges run side by side under IO.fork. bend-kit-dns resolves the host;
# TLS is bend-kit-wire's (OpenSSL 3 loaded at run time, BEND_LIBSSL to point
# at it).
#
# An exchange's answer is a status on its first line, then text: "0" and the
# raw response, or a non-zero status and the reason (wirespec.bend
# wire.fail). Every decision is wirespec.bend's: the deadline (wire.ms.of),
# the octets sent (wire.payload), what a failed call is reported as
# (wire.fail) and when the response is whole (wire.read.next), so a server
# that keeps the connection open after a complete response is not waited on
# (SPEC.md HTTP-CLI-1, 6, 10, 13; HTTP-TRUST-3, 5).
import Base
import bend-kit-wire@0.4.6.1/wire.bend as W
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import bend-kit-dns@0.6.0.2/dns.bend as Dns
import ./wirespec.bend as Spec

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

# a read that answered: its answer
def wire.end.of(r: Spec.Read) -> String:
  match r:
    case Spec.Heard{answer}:
      answer
    case Spec.Again{acc}:
      Spec.wire.spent()

# the held text went in: now the close
def wire.end.more(r: Spec.Read) -> String:
  match r:
    case Spec.Heard{answer}:
      answer
    case Spec.Again{acc}:
      wire.end.of(Spec.wire.read.next(acc, "0\n"))

# what the server's close leaves: the text still held, then the close
def wire.end(acc: Spec.Got, +text: String, none: Bool) -> String:
  match none:
    case True{}:
      wire.end.of(Spec.wire.read.next(acc, "0\n"))
    case False{}:
      wire.end.more(Spec.wire.read.next(acc, "0\n" ++ text))

# a judged read: read again, or close and answer
def wire.loop.on(+secure: Bool, s: Socket, r: Spec.Read,
  more: Socket -> Spec.Got -> IO(String)) -> IO(String):
  match r:
    case Spec.Again{acc}:
      more(s)(acc)
    case Spec.Heard{answer}:
      IO.bind(Unit, String, wire.close(secure, s),
        _u => IO.pure(String, answer))

# decoded text once it is known whether it is empty: read again when the
# octets finished no character, else judge the text
def wire.loop.judge(+secure: Bool, s: Socket, acc: Spec.Got, +text: String,
  held: List<&2, U32>, none: Bool,
  more: Socket -> List<&2, U32> -> Spec.Got -> IO(String)) -> IO(String):
  match none:
    case True{}:
      more(s)(held)(acc)
    case False{}:
      wire.loop.on(secure, s, Spec.wire.read.next(acc, "0\n" ++ text),
        s2 => a2 => more(s2)(held)(a2))

# octets that arrived, decoded with what was held
def wire.loop.text(+secure: Bool, s: Socket, acc: Spec.Got,
  t: String & List<&2, U32>,
  more: Socket -> List<&2, U32> -> Spec.Got -> IO(String)) -> IO(String):
  (+text, held) = t
  wire.loop.judge(secure, s, acc, text, held, String.is_empty(text), more)

# the server's close: what was held, decoded as it is, then the close
def wire.loop.closed(+secure: Bool, s: Socket, held: List<&2, U32>,
  acc: Spec.Got) -> IO(String):
  +text = Spec.wire.utf8.flush(held)
  IO.bind(Unit, String, wire.close(secure, s),
    _u => IO.pure(String, wire.end(acc, text, String.is_empty(text))))

# a receive's octets, or the server's close
def wire.loop.got(+secure: Bool, s: Socket, held: List<&2, U32>,
  acc: Spec.Got, +len: U32, buf: Array<U32>, closed: Bool,
  more: Socket -> List<&2, U32> -> Spec.Got -> IO(String)) -> IO(String):
  match closed:
    case True{}:
      wire.loop.closed(secure, s, held, acc)
    case False{}:
      wire.loop.text(secure, s, acc,
        Spec.wire.utf8.feed(held, Bytes.to_string(Bytes.Bytes{len, buf})),
        more)

# a receive's outcome: a failure is the answer
def wire.loop.un(+secure: Bool, +host: String, +port: U32, +ms: U32,
  held: List<&2, U32>, acc: Spec.Got,
  r: Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>,
  more: Socket -> List<&2, U32> -> Spec.Got -> IO(String)) -> IO(String):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      IO.bind(Unit, String, wire.close(secure, s),
        _u => IO.pure(String,
          Spec.wire.fail(Spec.Receive{}, host, port, ms, n, why)))
    case Done{(+len, buf)}:
      wire.loop.got(secure, s, held, acc, len, buf, U32.is_zero(len), more)

# receive until wirespec.bend says the answer is whole
def wire.loop(fuel: Nat, +secure: Bool, s: Socket, +host: String, +port: U32,
  +ms: U32, held: List<&2, U32>, acc: Spec.Got) -> IO(String):
  match fuel:
    case 0n:
      IO.bind(Unit, String, wire.close(secure, s),
        _u => IO.pure(String, Spec.wire.spent()))
    case 1n+p:
      IO.bind(Socket & Result<&1, &1, U32 & String, U32 & Array<U32>>, String,
        wire.recv(secure, s, ms),
        r => wire.loop.un(secure, host, port, ms, held, acc, r,
          s2 => h2 => a2 => wire.loop(p, secure, s2, host, port, ms, h2, a2)))

# --- one exchange ---

# after the send: read the answer, or the send's failure
def wire.after.send(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, r: Socket & Result<&1, &1, U32 & String, Unit>)
  -> IO(String):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      IO.bind(Unit, String, wire.close(secure, s),
        _u => IO.pure(String,
          Spec.wire.fail(Spec.Send{}, host, port, ms, n, why)))
    case Done{_u}:
      wire.loop(wire.reads(), secure, s, host, port, ms, [],
        Spec.wire.got(method, []))

# send the octets an exchange carries, then read its answer
def wire.put(+secure: Bool, s: Socket, +host: String, +port: U32, +ms: U32,
  +method: String, payload: Bytes.Bytes) -> IO(String):
  Bytes.Bytes{+len, buf} = payload
  IO.bind(Socket & Result<&1, &1, U32 & String, Unit>, String,
    wire.send(secure, s, len, buf, ms),
    r => wire.after.send(secure, host, port, ms, method, r))

# after the handshake: send, or the handshake's failure (the socket closed
# plainly, as no TLS session was made)
def wire.after.shake(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, payload: String,
  r: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(String):
  (s, res) = r
  match res:
    case Fail{(n, why)}:
      IO.bind(Unit, String, Socket.close(s),
        _u => IO.pure(String,
          Spec.wire.fail(Spec.Handshake{}, host, port, ms, n, why)))
    case Done{_u}:
      wire.put(secure, s, host, port, ms, method, Bytes.from_string(payload))

# after the connect: the handshake, or the connect's failure
def wire.after.connect(+secure: Bool, +host: String, +port: U32, +ms: U32,
  +method: String, payload: String,
  r: Result<&1, &1, U32 & String, Socket>) -> IO(String):
  match r:
    case Fail{(n, why)}:
      IO.pure(String, Spec.wire.fail(Spec.Connect{}, host, port, ms, n, why))
    case Done{s}:
      IO.bind(Socket & Result<&1, &1, U32 & String, Unit>, String,
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
  +method: String, payload: String,
  r: Result<&1, &1, U32 & String, List<&2, String>>) -> IO(String):
  match r:
    case Fail{(n, why)}:
      IO.pure(String, Spec.wire.fail(Spec.Resolve{}, host, port, ms, n, why))
    case Done{[]}:
      IO.pure(String, Spec.wire.fail(Spec.Resolve{}, host, port, ms, 2, ""))
    case Done{ip <> t}:
      IO.bind(Result<&1, &1, U32 & String, Socket>, String,
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

# a request with this method, sent to a host as wirespec.bend says, with
# its tail of octets after it, every call bounded by the deadline; its whole
# answer
def wire.run(+secure: Bool, +ms: U32, +host: String, +port: U32,
  +method: String, req: String, tail: List<&2, U32>) -> IO(String):
  IO.bind(Result<&1, &1, U32 & String, List<&2, String>>, String,
    wire.resolve(host, Dns.resolve.literal.all(host)),
    r => wire.after.resolve(secure, host, port, ms, method,
      Spec.wire.payload(req, tail), r))

# a request sent to a host, its tail of octets after it, and its whole answer
# read back, with the default deadline
def wire.talk(secure: Bool, host: String, port: U32, method: String,
  req: String, tail: List<&2, U32>) -> IO(String):
  wire.run(secure, Spec.wire.ms.of(None{}), host, port, method, req, tail)

# the same exchange, bounded by a timeout in milliseconds
def wire.talk.timed(secure: Bool, ms: U32, host: String, port: U32,
  method: String, req: String, tail: List<&2, U32>) -> IO(String):
  wire.run(secure, Spec.wire.ms.of(Some{ms}), host, port, method, req, tail)
