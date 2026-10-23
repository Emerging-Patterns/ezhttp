# ezhttp/src/wire: one request out and one response back. TLS and DNS stay in
# the effect (OpenSSL via dlopen); this module does not re-specify TLS.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim; the scheme line may carry a timeout
# (wirespec.bend). Answer: status on the first line, then text
# ("0" and the raw response, or a non-zero code and the reason).
#
# The effect opens a connection and sends the request, then answers one read
# at a time; when the response is whole is wirespec.bend's decision
# (wire.read.next), so a server that keeps the connection open after a
# complete response is not waited on (SPEC.md HTTP-CLI-5, HTTP-CLI-6).
import Base
import ./wirespec.bend as Spec

# connect, send the request a spec carries, and answer a connection number
def ezwire.open(spec: String) -> IO(String):
  import "./effs/wire.c"
  import "./effs/wire.js"

# the next octets a connection has received, "" once the server has closed
def ezwire.read(conn: U32) -> IO(String):
  import "./effs/wire.c"
  import "./effs/wire.js"

# close a connection
def ezwire.close(conn: U32) -> IO(Unit):
  import "./effs/wire.c"
  import "./effs/wire.js"

# the spec the effect reads (wirespec.bend)
def wire.spec(secure: Bool, host: String, port: U32, req: String) -> String:
  Spec.wire.spec(secure, host, port, req)

# the most reads one exchange makes
def wire.reads() -> Nat:
  65536n

# a read's outcome: read again, or the answer
def wire.loop.on(r: Spec.Read, more: String -> IO(String)) -> IO(String):
  match r:
    case Spec.Again{acc}:
      more(acc)
    case Spec.Heard{answer}:
      IO.pure(String, answer)

# read until wirespec.bend says the answer is whole
def wire.loop(fuel: Nat, +conn: U32, +method: String, acc: String)
  -> IO(String):
  match fuel:
    case 0n:
      IO.pure(String, Spec.wire.spent())
    case 1n+p:
      do IO<String>:
        +got : String <- ezwire.read(conn)
        wire.loop.on(Spec.wire.read.next(method, acc, got),
          next => wire.loop(p, conn, method, next))

# read the answer on an open connection, then close it
def wire.hear(+conn: U32, method: String) -> IO(String):
  do IO<String>:
    +answer : String <- wire.loop(wire.reads(), conn, method, "")
    _done : Unit <- ezwire.close(conn)
    IO.pure(String, answer)

# an open's outcome: read from the connection, or the answer
def wire.after(o: Spec.Opened, method: String) -> IO(String):
  match o:
    case Spec.Refused{answer}:
      IO.pure(String, answer)
    case Spec.Open{conn}:
      wire.hear(conn, method)

# a request with this method, sent as a spec says, and its whole answer
def wire.run(method: String, spec: String) -> IO(String):
  do IO<String>:
    +got : String <- ezwire.open(spec)
    wire.after(Spec.wire.opened(got), method)

# a request sent to a host and its whole answer read back
def wire.talk(secure: Bool, host: String, port: U32, method: String,
  req: String) -> IO(String):
  wire.run(method, wire.spec(secure, host, port, req))

# the same exchange, bounded by a timeout in milliseconds
def wire.talk.timed(secure: Bool, ms: U32, host: String, port: U32,
  method: String, req: String) -> IO(String):
  wire.run(method, Spec.wire.spec.timed(secure, ms, host, port, req))
