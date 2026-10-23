# ezhttp/src/server: listen, accept, parse one request, write one response.
# Uses Base TCP (no TLS in v0). One exchange per connection with
# Connection: close, one connection at a time. The handler returns IO; a pure
# one is lifted. Every decision after an effect is step.bend's, so a failed
# accept, recv or send loses that connection, logs one line and the server
# takes the next one (HTTP-SRV-4).
import Base
import ./http.bend as Http
import ./cors.bend as Cors
import ./step.bend as Step

# default recv budget for one request message
def server.max() -> U32:
  65536

# listen on a host address and port, e.g. "127.0.0.1" or "0.0.0.0"
# (RFC 9112 connection establishment stays at the socket)
def server.listen(host: String, port: U32) -> IO(Listener):
  IO.try(Listener, TCP.listen(host, port))

# accept one connection; a failed accept is a lost connection
def server.accept.un(
  pair: Listener & Result<&1, &1, U32 & String, Socket>
) -> IO(Listener & Step.Got<Socket>):
  (lst, res) = pair
  IO.pure(Listener & Step.Got<Socket>, (lst, Step.step.got(Socket, "accept", res)))

def server.accept(listener: Listener) -> IO(Listener & Step.Got<Socket>):
  IO.bind(
    Listener & Result<&1, &1, U32 & String, Socket>,
    Listener & Step.Got<Socket>,
    TCP.accept(listener),
    server.accept.un)

# the short-body refusal, so a partial recv can continue
def server.read.why() -> String:
  "the request body stopped before its Content-Length"

# whether this refusal is a body that has not arrived yet
def server.read.short(why: String) -> Bool:
  String.eq(why, server.read.why())

# a parsed request still wants more bytes
def server.read.need(req: Http.Request) -> Bool:
  match req:
    case Http.Bad{why}:
      server.read.short(why)
    case Http.Request{method, target, headers, body}:
      False{}

# how many extra recvs to chase a Content-Length
def server.read.fuel() -> Nat:
  64n

# parse what has arrived
def server.read.done(sock: Socket, got: String) -> IO(Socket & Step.Got<Http.Request>):
  IO.pure(Socket & Step.Got<Http.Request>, (sock, Step.Kept{Http.ask(got)}))

# stop on a finished message, or ask for another recv
def server.read.next(
  sock: Socket,
  got: String,
  req: Http.Request,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>),
  more: Bool
) -> IO(Socket & Step.Got<Http.Request>):
  match more:
    case False{}:
      IO.pure(Socket & Step.Got<Http.Request>, (sock, Step.Kept{req}))
    case True{}:
      rest(sock)(got)

# append a chunk and decide whether it completes the request
def server.read.grew(
  sock: Socket,
  +got: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>)
) -> IO(Socket & Step.Got<Http.Request>):
  +req = Http.ask(got)
  server.read.next(sock, got, req, rest, server.read.need(req))

# peer closed, or the chunk extends the buffer
def server.read.empty(
  sock: Socket,
  got: String,
  chunk: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>),
  closed: Bool
) -> IO(Socket & Step.Got<Http.Request>):
  match closed:
    case True{}:
      server.read.done(sock, got)
    case False{}:
      server.read.grew(sock, got ++ chunk, rest)

# one chunk of the request message
def server.read.use(
  sock: Socket,
  got: String,
  +chunk: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>)
) -> IO(Socket & Step.Got<Http.Request>):
  server.read.empty(sock, got, chunk, rest, String.eq(chunk, ""))

# None{} is the peer closing its write side; Some is the bytes that arrived
def server.read.got(
  sock: Socket,
  got: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>),
  chunk: Maybe<&1, String>
) -> IO(Socket & Step.Got<Http.Request>):
  match chunk:
    case None{}:
      server.read.done(sock, got)
    case Some{text}:
      server.read.use(sock, got, text, rest)

# the bytes from one recv; a failed recv loses the connection
def server.read.pass(
  sock: Socket,
  got: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>),
  chunk: Step.Got<Maybe<&1, String>>
) -> IO(Socket & Step.Got<Http.Request>):
  match chunk:
    case Step.Lost{line}:
      IO.pure(Socket & Step.Got<Http.Request>, (sock, Step.Lost{line}))
    case Step.Kept{text}:
      server.read.got(sock, got, rest, text)

# unpack recv's socket and result
def server.read.un(
  got: String,
  rest: Socket -> String -> IO(Socket & Step.Got<Http.Request>),
  pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>
) -> IO(Socket & Step.Got<Http.Request>):
  (sock, r) = pair
  server.read.pass(sock, got, rest,
    Step.step.got(Maybe<&1, String>, "read", r))

# recv until Content-Length is met, the peer closes, or fuel runs out.
# fuel is first so the recursive call is a decreasing self-call.
def server.read.go(fuel: Nat, sock: Socket, got: String) -> IO(Socket & Step.Got<Http.Request>):
  match fuel:
    case 0n:
      server.read.done(sock, got)
    case 1n+f:
      IO.bind(
        Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>,
        Socket & Step.Got<Http.Request>,
        TCP.recv(sock, server.max()),
        pair => server.read.un(got, s => g => server.read.go(f, s, g), pair))

# recv then parse an HTTP request (RFC 9112 §3)
def server.read(sock: Socket) -> IO(Socket & Step.Got<Http.Request>):
  server.read.go(server.read.fuel(), sock, "")

# write a structured response; a failed send loses the connection
def server.write.un(
  pair: Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>
) -> IO(Socket & Step.Got<Unit>):
  (sock, res) = pair
  IO.pure(Socket & Step.Got<Unit>, (sock, Step.step.sent(res)))

def server.write(sock: Socket, reply: Http.Reply) -> IO(Socket & Step.Got<Unit>):
  IO.bind(
    Socket & Result<&1, &1, (U32 & String) & List<&2, U32>, Unit>,
    Socket & Step.Got<Unit>,
    TCP.send(sock, Http.respond.of(reply)),
    server.write.un)

# turn a bad request into 400; otherwise call the handler
def server.dispatch(~handle: Http.Request -> Http.Reply, req: Http.Request)
  -> Http.Reply:
  match req:
    case Http.Bad{why}:
      Http.Reply{400, [], why}
    case Http.Request{method, target, headers, body}:
      handle(Http.Request{method, target, headers, body})

# apply HEAD body stripping once the method token is known
def server.reply.built(~handle: Http.Request -> Http.Reply, method: String,
  req: Http.Request) -> Http.Reply:
  Http.reply.for(method, server.dispatch(handle, req))

# HEAD responses are written with an empty body (RFC 9110 §9.3.2)
def server.reply(~handle: Http.Request -> Http.Reply, req: Http.Request)
  -> Http.Reply:
  match req:
    case Http.Bad{why}:
      server.dispatch(handle, Http.Bad{why})
    case Http.Request{+method, target, headers, body}:
      server.reply.built(handle, method,
        Http.Request{method, target, headers, body})

# CORS preflight or simple headers, after HEAD bodies are dropped
def server.cors_reply(
  ~handle: Http.Request -> Http.Reply,
  cfg: Cors.Cfg,
  +req: Http.Request
) -> Http.Reply:
  Cors.cors.on(cfg, req, server.reply(handle, req))

# a lost connection logs its line and closes
def server.lose(sock: Socket, line: String) -> IO(Unit):
  IO.bind(Unit, Unit, IO.print_err(line), _u => Socket.close(sock))

# after the write: close, logging first when the send failed
def server.sent.got(sock: Socket, got: Step.Got<Unit>) -> IO(Unit):
  match got:
    case Step.Lost{line}:
      server.lose(sock, line)
    case Step.Kept{_u}:
      Socket.close(sock)

def server.sent(pair: Socket & Step.Got<Unit>) -> IO(Unit):
  (sock, got) = pair
  server.sent.got(sock, got)

# write a reply shaped for the request's method (HTTP-SRV-3), then close
def server.answer(sock: Socket, method: String, reply: Http.Reply) -> IO(Unit):
  IO.bind(Socket & Step.Got<Unit>, Unit,
    server.write(sock, Http.reply.for(method, reply)), server.sent)

# answer now, or call the handler: step.bend decides which (HTTP-SRV-1, 2)
def server.step(
  ~handle: Http.Request -> IO(Http.Reply),
  sock: Socket,
  +method: String,
  step: Step.Step
) -> IO(Unit):
  match step:
    case Step.Answer{reply}:
      server.answer(sock, method, reply)
    case Step.Call{req}:
      IO.bind(Http.Reply, Unit, handle(req),
        reply => server.answer(sock, method, reply))

# after the read: a lost connection, or a request to step
def server.exchange.got(
  ~handle: Http.Request -> IO(Http.Reply),
  sock: Socket,
  got: Step.Got<Http.Request>
) -> IO(Unit):
  match got:
    case Step.Lost{line}:
      server.lose(sock, line)
    case Step.Kept{+req}:
      server.step(handle, sock, Http.method.of(req), Step.step.of(req))

def server.exchange.un(
  ~handle: Http.Request -> IO(Http.Reply),
  pair: Socket & Step.Got<Http.Request>
) -> IO(Unit):
  (sock, got) = pair
  server.exchange.got(handle, sock, got)

# one connection: read, decide, maybe handle, write, close
def server.exchange(
  ~handle: Http.Request -> IO(Http.Reply),
  sock: Socket
) -> IO(Unit):
  IO.bind(Socket & Step.Got<Http.Request>, Unit, server.read(sock),
    pair => server.exchange.un(handle, pair))

# how long a failed accept waits before the next, so EMFILE does not spin
def server.pause() -> U32:
  100

# after accept: serve the connection, or log a failed accept and pause, then
# call `again` with the listener either way. `again` is a runtime closure so
# it can carry the fuel still left.
def server.loop.got(
  ~handle: Http.Request -> IO(Http.Reply),
  again: Listener -> IO(Unit),
  lst: Listener,
  got: Step.Got<Socket>
) -> IO(Unit):
  match got:
    case Step.Lost{line}:
      IO.bind(Unit, Unit, IO.print_err(line), _u =>
        IO.bind(Unit, Unit, IO.sleep(server.pause()), _v => again(lst)))
    case Step.Kept{sock}:
      IO.bind(Unit, Unit, server.exchange(handle, sock), _u => again(lst))

def server.loop.cont(
  ~handle: Http.Request -> IO(Http.Reply),
  again: Listener -> IO(Unit),
  pair: Listener & Step.Got<Socket>
) -> IO(Unit):
  (lst, got) = pair
  server.loop.got(handle, again, lst, got)

# fuel-bounded accept loop (self-recursive); a failed accept spends fuel too
def server.loop.go(
  ~handle: Http.Request -> IO(Http.Reply),
  fuel: Nat,
  listener: Listener
) -> IO(Unit):
  match fuel:
    case 0n:
      Listener.close(listener)
    case 1n+f:
      IO.bind(Listener & Step.Got<Socket>, Unit, server.accept(listener),
        pair => server.loop.cont(handle,
          lst => server.loop.go(handle, f, lst), pair))

# listen and serve up to `limit` connections with an IO handler
def server.serve_io(
  ~handle: Http.Request -> IO(Http.Reply),
  host: String,
  port: U32,
  limit: U32
) -> IO(Unit):
  IO.bind(Listener, Unit, server.listen(host, port),
    lst => server.loop.go(handle, U32.to_nat(limit), lst))

# a pure handler as an IO one
def server.lift(
  ~handle: Http.Request -> Http.Reply,
  req: Http.Request
) -> IO(Http.Reply):
  IO.pure(Http.Reply, handle(req))

# listen and serve up to `limit` connections
def server.serve(
  ~handle: Http.Request -> Http.Reply,
  host: String,
  port: U32,
  limit: U32
) -> IO(Unit):
  server.serve_io(~(req => server.lift(handle, req)), host, port, limit)

# serve exactly one connection then stop
def server.once(
  ~handle: Http.Request -> Http.Reply,
  host: String,
  port: U32
) -> IO(Unit):
  server.serve(handle, host, port, 1)

# the accept loop with no fuel: it runs until the process is stopped
# (HTTP-TRUST-2)
@unsafe def server.forever.go(
  ~handle: Http.Request -> IO(Http.Reply),
  listener: Listener
) -> IO(Unit):
  IO.bind(Listener & Step.Got<Socket>, Unit, server.accept(listener),
    pair => server.loop.cont(handle,
      lst => server.forever.go(handle, lst), pair))

# listen and serve with an IO handler until the process is stopped
@unsafe def server.serve_forever(
  ~handle: Http.Request -> IO(Http.Reply),
  host: String,
  port: U32
) -> IO(Unit):
  IO.bind(Listener, Unit, server.listen(host, port),
    lst => server.forever.go(handle, lst))
