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

# recv then parse an HTTP request (RFC 9112 §3)
def server.read.got(sock: Socket, raw: String) -> IO(Socket & Http.Request):
  IO.pure(Socket & Http.Request, (sock, Http.ask(raw)))

def server.read.res(sock: Socket, r: Result<&1, &1, U32 & String, String>)
  -> IO(Socket & Http.Request):
  IO.bind(String, Socket & Http.Request, IO.pass(String, r),
    raw => server.read.got(sock, raw))

def server.read.un(pair: Socket & Result<&1, &1, U32 & String, String>)
  -> IO(Socket & Http.Request):
  (s, r) = pair
  server.read.res(s, r)

def server.read(sock: Socket) -> IO(Socket & Http.Request):
  IO.bind(
    Socket & Result<&1, &1, U32 & String, String>,
    Socket & Http.Request,
    TCP.recv(sock, server.max()),
    server.read.un)

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

# continue after accept: exchange, then call `again` with the listener
def server.loop.cont(
  ~handle: Http.Request -> Http.Reply,
  ~again: Listener -> IO(Unit),
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
