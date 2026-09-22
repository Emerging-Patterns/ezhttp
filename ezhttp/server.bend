# ezhttp/server: listen, accept, parse one request, write one response.
# Uses Base TCP (no TLS in v0). One exchange per connection with
# Connection: close. Handler is a pure Request -> Reply function.
import Base
import ./http.bend as Http
import ./cors.bend as Cors

# default recv budget for one request message
def server.max() -> U32:
  65536

# listen on a port (RFC 9112 connection establishment stays at the socket)
def server.listen(port: U32) -> IO(Listener):
  IO.try(Listener, TCP.listen(port))

# unpack accept: listener stays, socket from the Result
def server.accept.of(
  lst: Listener,
  res: Result<&1, &1, U32 & String, Socket>
) -> IO(Listener & Socket):
  do IO<Listener & Socket>:
    sock : Socket <- IO.pass(Socket, res)
    IO.pure(Listener & Socket, (lst, sock))

def server.accept.un(pair: Listener & Result<&1, &1, U32 & String, Socket>)
  -> IO(Listener & Socket):
  (lst, res) = pair
  server.accept.of(lst, res)

def server.accept(listener: Listener) -> IO(Listener & Socket):
  IO.bind(
    Listener & Result<&1, &1, U32 & String, Socket>,
    Listener & Socket,
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
def server.read.done(sock: Socket, got: String) -> IO(Socket & Http.Request):
  IO.pure(Socket & Http.Request, (sock, Http.ask(got)))

# stop on a finished message, or ask for another recv
def server.read.next(
  sock: Socket,
  got: String,
  req: Http.Request,
  rest: Socket -> String -> IO(Socket & Http.Request),
  more: Bool
) -> IO(Socket & Http.Request):
  match more:
    case False{}:
      IO.pure(Socket & Http.Request, (sock, req))
    case True{}:
      rest(sock)(got)

# append a chunk and decide whether it completes the request
def server.read.grew(
  sock: Socket,
  +got: String,
  rest: Socket -> String -> IO(Socket & Http.Request)
) -> IO(Socket & Http.Request):
  +req = Http.ask(got)
  server.read.next(sock, got, req, rest, server.read.need(req))

# peer closed, or the chunk extends the buffer
def server.read.empty(
  sock: Socket,
  got: String,
  chunk: String,
  rest: Socket -> String -> IO(Socket & Http.Request),
  closed: Bool
) -> IO(Socket & Http.Request):
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
  rest: Socket -> String -> IO(Socket & Http.Request)
) -> IO(Socket & Http.Request):
  server.read.empty(sock, got, chunk, rest, String.eq(chunk, ""))

# the bytes from one recv
def server.read.pass(
  sock: Socket,
  got: String,
  rest: Socket -> String -> IO(Socket & Http.Request),
  r: Result<&1, &1, U32 & String, String>
) -> IO(Socket & Http.Request):
  IO.bind(String, Socket & Http.Request, IO.pass(String, r),
    chunk => server.read.use(sock, got, chunk, rest))

# unpack recv's socket and result
def server.read.un(
  got: String,
  rest: Socket -> String -> IO(Socket & Http.Request),
  pair: Socket & Result<&1, &1, U32 & String, String>
) -> IO(Socket & Http.Request):
  (sock, r) = pair
  server.read.pass(sock, got, rest, r)

# recv until Content-Length is met, the peer closes, or fuel runs out.
# fuel is first so the recursive call is a decreasing self-call.
def server.read.go(fuel: Nat, sock: Socket, got: String) -> IO(Socket & Http.Request):
  match fuel:
    case 0n:
      server.read.done(sock, got)
    case 1n+f:
      IO.bind(
        Socket & Result<&1, &1, U32 & String, String>,
        Socket & Http.Request,
        TCP.recv(sock, server.max()),
        pair => server.read.un(got, s => g => server.read.go(f, s, g), pair))

# recv then parse an HTTP request (RFC 9112 §3)
def server.read(sock: Socket) -> IO(Socket & Http.Request):
  server.read.go(server.read.fuel(), sock, "")

# write a structured response and keep the socket
def server.write.res(sock: Socket, r: Result<&1, &1, U32 & String, Unit>)
  -> IO(Socket):
  IO.bind(Unit, Socket, IO.pass(Unit, r), _u => IO.pure(Socket, sock))

def server.write.un(pair: Socket & Result<&1, &1, U32 & String, Unit>)
  -> IO(Socket):
  (s, r) = pair
  server.write.res(s, r)

def server.write(sock: Socket, reply: Http.Reply) -> IO(Socket):
  IO.bind(
    Socket & Result<&1, &1, U32 & String, Unit>,
    Socket,
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

# after read: write the handler's reply and close
def server.exchange.go(
  ~handle: Http.Request -> Http.Reply,
  sock: Socket,
  req: Http.Request
) -> IO(Unit):
  IO.bind(Socket, Unit, server.write(sock, server.reply(handle, req)),
    Socket.close)

def server.exchange.un(
  ~handle: Http.Request -> Http.Reply,
  pair: Socket & Http.Request
) -> IO(Unit):
  (s, req) = pair
  server.exchange.go(handle, s, req)

# one connection: read, handle, write, close
def server.exchange(~handle: Http.Request -> Http.Reply, sock: Socket)
  -> IO(Unit):
  IO.bind(Socket & Http.Request, Unit, server.read(sock),
    pair => server.exchange.un(handle, pair))

# continue after accept: exchange, then call `again` with the listener.
# `again` is a runtime closure so it can carry the fuel still left.
def server.loop.cont(
  ~handle: Http.Request -> Http.Reply,
  again: Listener -> IO(Unit),
  pair: Listener & Socket
) -> IO(Unit):
  (lst, sock) = pair
  IO.bind(Unit, Unit, server.exchange(handle, sock),
    _u => again(lst))

# fuel-bounded accept loop (self-recursive)
def server.loop.go(
  ~handle: Http.Request -> Http.Reply,
  fuel: Nat,
  listener: Listener
) -> IO(Unit):
  match fuel:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+f:
      IO.bind(Listener & Socket, Unit, server.accept(listener),
        pair => server.loop.cont(handle,
          lst => server.loop.go(handle, f, lst), pair))

# listen and serve up to `limit` connections (fuel from the limit)
def server.loop(
  ~handle: Http.Request -> Http.Reply,
  listener: Listener,
  limit: U32
) -> IO(Unit):
  server.loop.go(handle, U32.to_nat(limit), listener)

# listen and serve up to `limit` connections
def server.serve(
  ~handle: Http.Request -> Http.Reply,
  port: U32,
  limit: U32
) -> IO(Unit):
  IO.bind(Listener, Unit, server.listen(port),
    lst => server.loop(handle, lst, limit))

# serve exactly one connection then stop
def server.once.cont(
  ~handle: Http.Request -> Http.Reply,
  pair: Listener & Socket
) -> IO(Unit):
  (lst, sock) = pair
  IO.bind(Unit, Unit, server.exchange(handle, sock),
    _u => Listener.close(lst))

def server.once(~handle: Http.Request -> Http.Reply, port: U32) -> IO(Unit):
  IO.bind(Listener, Unit, server.listen(port), lst =>
    IO.bind(Listener & Socket, Unit, server.accept(lst),
      pair => server.once.cont(handle, pair)))
