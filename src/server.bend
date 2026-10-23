# ezhttp/src/server: listen, accept, and serve each connection on its own
# fork: parse one request, write one response (Connection: close). Sockets
# are Base's (listen) and bend-kit-wire's (accept with a deadline, recv,
# send.words), whose effects park on the event loop, so connections overlap.
# A `_with` serve hands the handler a context value and the request as text
# with its body's octets, and takes a reply as text, packed octets or a
# stream of octet chunks; the plain serves are those with a text handler.
# Every decision after an effect is step.bend's or http.bend's (SPEC.md
# HTTP-SRV); this module runs the effects in order (HTTP-TRUST-2).
import Base
import bend-kit-wire@0.4.6.1/wire.bend as W
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import ./http.bend as Http
import ./cors.bend as Cors
import ./step.bend as Step
import ./wirespec.bend as Spec

# what a `_with` handler gets: the request as text (step.text) and its
# body's octets as they arrived (step.octets)
type Req is Type:  # noqa: L001 it holds Bytes; step.text and step.octets fill it (HTTP-SRV-9)
  Req{method: String, target: String, headers: List<&2, Http.Header>,
    body: String, bytes: Bytes.Bytes}

# what a `_with` handler answers: a text body (written as UTF-8), packed
# octets written unchanged, or a stream of octet chunks from a channel,
# written chunked until the channel is closed (SPEC.md HTTP-SRV-6, 7)
type Answer is Type:  # noqa: L001 it holds Bytes and a channel; HTTP-SRV-6 to 8 cover its writing
  TextReply{status: U32, headers: List<&2, Http.Header>, body: String}
  OctetsReply{status: U32, headers: List<&2, Http.Header>, bytes: Bytes.Bytes}
  StreamReply{status: U32, headers: List<&2, Http.Header>,
    chunks: Chan(Bytes.Bytes)}

# the most octets one receive asks for
def server.max() -> U32:
  65536

# the most receives one request takes
def server.reads() -> Nat:
  65536n

# how long one accept waits before it is asked again, in ms
def server.wait() -> U32:
  3600000

# how many idle accepts in a row a limited serve allows before it stops
def server.idles() -> Nat:
  1000000n

# how long a failed accept waits before the next, so EMFILE does not spin
def server.pause() -> U32:
  100

# listen on a host address and port, e.g. "127.0.0.1" or "0.0.0.0"
def server.listen(host: String, port: U32) -> IO(Listener):
  IO.try(Listener, TCP.listen(host, port))

# accept one connection, waiting at most server.wait() ms
def server.accept.un(r: Listener & Result<&1, &1, U32 & String, Socket>)
  -> IO(Listener & Step.Accept<Socket>):
  (lst, res) = r
  IO.pure(Listener & Step.Accept<Socket>, (lst, Step.step.accepted(Socket, res)))

def server.accept(listener: Listener) -> IO(Listener & Step.Accept<Socket>):
  IO.bind(Listener & Result<&1, &1, U32 & String, Socket>,
    Listener & Step.Accept<Socket>,
    W.accept.deadline(listener, server.wait()), server.accept.un)

# a lost connection logs its line and closes
def server.lose(sock: Socket, line: String) -> IO(Unit):
  IO.bind(Unit, Unit, IO.print_err(line), _u => Socket.close(sock))

# --- reading a request ---

# the request once it has all arrived (or the peer closed, or the receives
# ran out): its pieces put together and parsed
def server.read.done(sock: Socket, ps: List<&2, String>)
  -> IO(Socket & Step.Got<Http.Request>):
  IO.pure(Socket & Step.Got<Http.Request>,
    (sock, Step.Kept{Http.ask(Spec.wire.join(ps))}))

# what the request needs, kept once its head has ended
def server.read.needs(m: Maybe<&2, Nat>, ps: List<&2, String>)
  -> Maybe<&2, Nat>:
  match m:
    case None{}:
      Step.step.need(Spec.wire.join(ps))
    case Some{n}:
      Some{n}

# whether as much has arrived as the request needs
def server.read.whole(m: Maybe<&2, Nat>, +have: Nat) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{n}:
      Bool.not(Nat.is_lt(have, n))

# octets that arrived: stop when the request is whole, else read again
def server.read.more(sock: Socket, +ps: List<&2, String>, +have: Nat,
  +need: Maybe<&2, Nat>, whole: Bool,
  rest: Socket -> List<&2, String> -> Nat -> Maybe<&2, Nat>
    -> IO(Socket & Step.Got<Http.Request>))
  -> IO(Socket & Step.Got<Http.Request>):
  match whole:
    case True{}:
      server.read.done(sock, ps)
    case False{}:
      rest(sock)(ps)(have)(need)

# octets added to the pieces: is the request now whole?
def server.read.add(sock: Socket, +ps: List<&2, String>, +have: Nat,
  need: Maybe<&2, Nat>,
  rest: Socket -> List<&2, String> -> Nat -> Maybe<&2, Nat>
    -> IO(Socket & Step.Got<Http.Request>))
  -> IO(Socket & Step.Got<Http.Request>):
  +need2 = server.read.needs(need, ps)
  server.read.more(sock, ps, have, need2, server.read.whole(need2, have), rest)

# octets that arrived, or none once the peer has closed
def server.read.text(sock: Socket, +ps: List<&2, String>, +have: Nat,
  need: Maybe<&2, Nat>, +text: String, closed: Bool,
  rest: Socket -> List<&2, String> -> Nat -> Maybe<&2, Nat>
    -> IO(Socket & Step.Got<Http.Request>))
  -> IO(Socket & Step.Got<Http.Request>):
  match closed:
    case True{}:
      server.read.done(sock, ps)
    case False{}:
      server.read.add(sock, text <> ps, Nat.add(have, String.length(text)),
        need, rest)

# a receive's answer: a failure loses the connection, no octets is the peer
# closing, octets go onto the pieces
def server.read.got(+ps: List<&2, String>, +have: Nat, need: Maybe<&2, Nat>,
  r: Socket & Result<&1, &1, U32 & String, String>,
  rest: Socket -> List<&2, String> -> Nat -> Maybe<&2, Nat>
    -> IO(Socket & Step.Got<Http.Request>))
  -> IO(Socket & Step.Got<Http.Request>):
  (sock, res) = r
  match res:
    case Fail{(code, why)}:
      IO.pure(Socket & Step.Got<Http.Request>,
        (sock, Step.Lost{Step.step.line("read", why)}))
    case Done{+text}:
      server.read.text(sock, ps, have, need, text, String.is_empty(text), rest)

# receive until the head has ended and its Content-Length has arrived, the
# peer closes, or the receives run out
def server.read.go(fuel: Nat, sock: Socket, +ps: List<&2, String>, +have: Nat,
  +need: Maybe<&2, Nat>) -> IO(Socket & Step.Got<Http.Request>):
  match fuel:
    case 0n:
      server.read.done(sock, ps)
    case 1n+f:
      IO.bind(Socket & Result<&1, &1, U32 & String, String>,
        Socket & Step.Got<Http.Request>,
        W.recv(sock, server.max(), 0),
        r => server.read.got(ps, have, need, r,
          s => p => h => m => server.read.go(f, s, p, h, m)))

# receive then parse an HTTP request (RFC 9112 §3)
def server.read(sock: Socket) -> IO(Socket & Step.Got<Http.Request>):
  server.read.go(server.reads(), sock, [], 0n, None{})

# --- writing a reply ---

# after a send: the socket, or the line of a lost connection
def server.sent.un(r: Socket & Result<&1, &1, U32 & String, Unit>)
  -> IO(Socket & Step.Got<Unit>):
  (sock, res) = r
  IO.pure(Socket & Step.Got<Unit>, (sock, Step.step.got(Unit, "write", res)))

# send octets
def server.send(sock: Socket, b: Bytes.Bytes) -> IO(Socket & Step.Got<Unit>):
  Bytes.Bytes{+len, buf} = b
  IO.bind(Socket & Result<&1, &1, U32 & String, Unit>, Socket & Step.Got<Unit>,
    W.send.words(sock, len, buf), server.sent.un)

# send text as its UTF-8 octets
def server.send.text(sock: Socket, text: String) -> IO(Socket & Step.Got<Unit>):
  server.send(sock, Bytes.from_string(Spec.wire.payload(text)))

# after the last send: close, logging first when it failed
def server.close(r: Socket & Step.Got<Unit>) -> IO(Unit):
  (sock, got) = r
  match got:
    case Step.Lost{line}:
      server.lose(sock, line)
    case Step.Kept{_u}:
      Socket.close(sock)

# after a send in the middle: go on, or lose the connection
def server.then(r: Socket & Step.Got<Unit>, more: Socket -> IO(Unit))
  -> IO(Unit):
  (sock, got) = r
  match got:
    case Step.Lost{line}:
      server.lose(sock, line)
    case Step.Kept{_u}:
      more(sock)

# a text reply shaped for the request's method (HTTP-SRV-3), then close
def server.answer(sock: Socket, method: String, reply: Http.Reply) -> IO(Unit):
  IO.bind(Socket & Step.Got<Unit>, Unit,
    server.send.text(sock, Http.respond.of(Http.reply.for(method, reply))),
    server.close)

# an octets reply once its length is known: its head, then its octets
# unless it is bare (HTTP-SRV-6, 8)
def server.octets.go(sock: Socket, +status: U32, headers: List<&2, Http.Header>,
  r: Bytes.Bytes & U32, bare: Bool) -> IO(Unit):
  (b, +n) = r
  match bare:
    case True{}:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send.text(sock, Http.respond.head(status, headers, 0n)),
        server.close)
    case False{}:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send(sock, Bytes.append(Bytes.from_string(
          Http.respond.head(status, headers, U32.to_nat(n))), b)),
        server.close)

# the most chunks one streamed reply writes
def server.chunks() -> Nat:
  U32.to_nat(4294967295)

# one chunk the channel gave: framed and sent, or skipped when empty
def server.chunk.put(sock: Socket, c: Http.Chunk, b: Bytes.Bytes,
  more: Socket -> IO(Unit)) -> IO(Unit):
  match c:
    case Http.NoChunk{}:
      more(sock)
    case Http.Chunk{line}:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send(sock, Bytes.append(Bytes.append(Bytes.from_string(line), b),
          Bytes.from_string("\r\n"))),
        r => server.then(r, more))

# a chunk with its length known
def server.chunk.sized(sock: Socket, r: Bytes.Bytes & U32,
  more: Socket -> IO(Unit)) -> IO(Unit):
  (b, +n) = r
  server.chunk.put(sock, Http.chunk.frame(n), b, more)

# what the channel gave: a chunk, or its close, which ends the body
def server.chunk.got(sock: Socket, m: Maybe<&1, Bytes.Bytes>,
  more: Socket -> IO(Unit)) -> IO(Unit):
  match m:
    case None{}:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send.text(sock, Http.chunk.end()), server.close)
    case Some{b}:
      server.chunk.sized(sock, Bytes.length(b), more)

# every chunk the channel gives, until it is closed
def server.stream.go(fuel: Nat, sock: Socket, +ch: Chan(Bytes.Bytes))
  -> IO(Unit):
  match fuel:
    case 0n:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send.text(sock, Http.chunk.end()), server.close)
    case 1n+f:
      IO.bind(Maybe<&1, Bytes.Bytes>, Unit, Chan.recv(Bytes.Bytes, ch),
        m => server.chunk.got(sock, m, s => server.stream.go(f, s, ch)))

# a streamed reply after its head: its chunks, or nothing when it is bare
def server.stream.body(sock: Socket, +ch: Chan(Bytes.Bytes), bare: Bool)
  -> IO(Unit):
  match bare:
    case True{}:
      IO.bind(Unit, Unit, Chan.close(Bytes.Bytes, ch), _u => Socket.close(sock))
    case False{}:
      server.stream.go(server.chunks(), sock, ch)

# a handler's answer, shaped for the request's method (HTTP-SRV-3, 6 to 8)
def server.reply(sock: Socket, +method: String, a: Answer) -> IO(Unit):
  match a:
    case TextReply{status, headers, body}:
      server.answer(sock, method, Http.Reply{status, headers, body})
    case OctetsReply{+status, headers, bytes}:
      server.octets.go(sock, status, headers, Bytes.length(bytes),
        Step.step.bare(method, status))
    case StreamReply{+status, +headers, +chunks}:
      IO.bind(Socket & Step.Got<Unit>, Unit,
        server.send.text(sock, Http.respond.stream(status, headers)),
        r => server.then(r,
          s => server.stream.body(s, chunks, Step.step.bare(method, status))))

# --- one connection ---

# the handler's request: the request as text and its body's octets
def server.req(req: Http.Request, +octets: String) -> Req:
  match req:
    case Http.Bad{why}:
      Req{"", "", [], why, Bytes.from_string(octets)}
    case Http.Request{method, target, headers, body}:
      Req{method, target, headers, body, Bytes.from_string(octets)}

# answer now, or call the handler: step.bend decides which (HTTP-SRV-1, 2, 9)
def server.step(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  sock: Socket, +method: String, +octets: String, step: Step.Step) -> IO(Unit):
  match step:
    case Step.Answer{reply}:
      server.answer(sock, method, reply)
    case Step.Call{req}:
      IO.bind(Answer, Unit, handle(ctx)(server.req(req, octets)),
        a => server.reply(sock, method, a))

# after the read: a lost connection, or a request to step
def server.conn.got(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  r: Socket & Step.Got<Http.Request>) -> IO(Unit):
  (sock, got) = r
  match got:
    case Step.Lost{line}:
      server.lose(sock, line)
    case Step.Kept{+raw}:
      +req = Step.step.text(raw)
      server.step(~C, handle, ctx, sock, Http.method.of(req),
        Step.step.octets(raw), Step.step.of(req))

# one connection: read, decide, maybe handle, write, close
def server.conn(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  sock: Socket) -> IO(Unit):
  IO.bind(Socket & Step.Got<Http.Request>, Unit, server.read(sock),
    r => server.conn.got(~C, handle, ctx, r))

# --- the accept loop ---

# give a slot back
def server.slot.give(+slots: Chan(Unit), limited: Bool) -> IO(Unit):
  match limited:
    case True{}:
      IO.bind(Maybe<&1, Unit>, Unit, Chan.recv(Unit, slots),
        _m => IO.pure(Unit, Unit{}))
    case False{}:
      IO.pure(Unit, Unit{})

# take a slot, waiting while every one is taken
def server.slot.take(+slots: Chan(Unit), limited: Bool) -> IO(Unit):
  match limited:
    case True{}:
      IO.bind(Result<&1, &1, Unit, Unit>, Unit, Chan.send(Unit, slots, Unit{}),
        _r => IO.pure(Unit, Unit{}))
    case False{}:
      IO.pure(Unit, Unit{})

# say a fork is done, when the serve waits for its forks
def server.done(+done: Chan(Unit), tracked: Bool) -> IO(Unit):
  match tracked:
    case True{}:
      IO.bind(Result<&1, &1, Unit, Unit>, Unit, Chan.send(Unit, done, Unit{}),
        _r => IO.pure(Unit, Unit{}))
    case False{}:
      IO.pure(Unit, Unit{})

# a connection's fork: serve it, give its slot back, and say it is done
def server.fork.body(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  sock: Socket, +slots: Chan(Unit), +limited: Bool, +done: Chan(Unit),
  +tracked: Bool) -> IO(Unit):
  IO.bind(Unit, Unit, server.conn(~C, handle, ctx, sock),
    _u => IO.bind(Unit, Unit, server.slot.give(slots, limited),
      _v => server.done(done, tracked)))

# serve an accepted connection on its own fork, a slot taken first
def server.fork(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  sock: Socket, +slots: Chan(Unit), +limited: Bool, +done: Chan(Unit),
  +tracked: Bool) -> IO(Unit):
  IO.bind(Unit, Unit, server.slot.take(slots, limited),
    _u => IO.spawn(Unit,
      server.fork.body(~C, handle, ctx, sock, slots, limited, done, tracked)))

# wait for n forks to say they are done
def server.join(n: Nat, +done: Chan(Unit)) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      IO.bind(Maybe<&1, Unit>, Unit, Chan.recv(Unit, done),
        _m => server.join(p, done))

# what an accept brought, for the loop: `took` serves a connection and goes
# on with one connection fewer, `idle` accepts again, `missed` logs, pauses
# and goes on with one fewer (a failed accept counts toward the limit)
def server.loop.got(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  +slots: Chan(Unit), +limited: Bool, +done: Chan(Unit), +tracked: Bool,
  r: Listener & Step.Accept<Socket>, took: Listener -> IO(Unit),
  idle: Listener -> IO(Unit), missed: Listener -> IO(Unit)) -> IO(Unit):
  (lst, got) = r
  match got:
    case Step.Took{sock}:
      IO.bind(Unit, Unit,
        server.fork(~C, handle, ctx, sock, slots, limited, done, tracked),
        _u => took(lst))
    case Step.Idle{}:
      idle(lst)
    case Step.Missed{line}:
      IO.bind(Unit, Unit, IO.print_err(line), _u =>
        IO.bind(Unit, Unit, IO.sleep(server.pause()), _v => missed(lst)))

# the limited accept loop: `fuel` connections left, `idles` idle accepts in
# a row left, `forks` forked so far
def server.loop.go(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  fuel: Nat, idles: Nat, +forks: Nat, +slots: Chan(Unit), +limited: Bool,
  +done: Chan(Unit), listener: Listener) -> IO(Unit):
  match fuel idles:
    case 0n _:
      IO.bind(Unit, Unit, Listener.close(listener), _u => server.join(forks, done))
    case 1n+_f 0n:
      IO.bind(Unit, Unit, Listener.close(listener), _u => server.join(forks, done))
    case 1n+f0 1n+i:
      +f = f0
      IO.bind(Listener & Step.Accept<Socket>, Unit, server.accept(listener),
        r => server.loop.got(~C, handle, ctx, slots, limited, done, True{}, r,
          l => server.loop.go(~C, handle, ctx, f, server.idles(), 1n+forks, slots,
            limited, done, l),
          l => server.loop.go(~C, handle, ctx, 1n+f, i, forks, slots, limited,
            done, l),
          l => server.loop.go(~C, handle, ctx, f, server.idles(), forks, slots,
            limited, done, l)))

# the slots a concurrency limit allows (max 0: no limit)
def server.slots(+max: U32) -> IO(Chan(Unit)):
  Chan.new(Unit, Bool.pick(U32, U32.is_eq(max, 0), 1, max))

# listen and serve up to `limit` connections, each on its own fork, at most
# `max` at once (0: no limit), with a context value for the handler; returns
# once every fork is done (SPEC.md HTTP-TRUST-2)
def server.serve_io_with(~C: Data, ~handle: C -> Req -> IO(Answer), +ctx: C,
  host: String, port: U32, limit: U32, +max: U32) -> IO(Unit):
  do IO<Unit>:
    lst : Listener <- server.listen(host, port)
    +slots : Chan(Unit) <- server.slots(max)
    +done : Chan(Unit) <- Chan.new(Unit, 1024)
    server.loop.go(~C, handle, ctx, U32.to_nat(limit), server.idles(), 0n, slots,
      Bool.not(U32.is_eq(max, 0)), done, lst)

# a pure handler as an IO one
def server.lift.with(~C: Data, ~handle: C -> Req -> Answer, +ctx: C, req: Req)
  -> IO(Answer):
  IO.pure(Answer, handle(ctx)(req))

# listen and serve with a pure handler and a context value
def server.serve_with(~C: Data, ~handle: C -> Req -> Answer, +ctx: C,
  host: String, port: U32, limit: U32, max: U32) -> IO(Unit):
  server.serve_io_with(~C, ~(c => r => server.lift.with(~C, handle, c, r)), ctx,
    host, port, limit, max)

# the accept loop with no limit: it runs until the process is stopped
@unsafe def server.forever.go(~C: Data, ~handle: C -> Req -> IO(Answer),
  +ctx: C, +slots: Chan(Unit), +limited: Bool, +done: Chan(Unit),
  listener: Listener) -> IO(Unit):
  IO.bind(Listener & Step.Accept<Socket>, Unit, server.accept(listener),
    r => server.loop.got(~C, handle, ctx, slots, limited, done, False{}, r,
      l => server.forever.go(~C, handle, ctx, slots, limited, done, l),
      l => server.forever.go(~C, handle, ctx, slots, limited, done, l),
      l => server.forever.go(~C, handle, ctx, slots, limited, done, l)))

# listen and serve with an IO handler and a context value until the process
# is stopped, at most `max` connections at once (0: no limit)
@unsafe def server.serve_forever_with(~C: Data,
  ~handle: C -> Req -> IO(Answer), +ctx: C, host: String, port: U32, +max: U32)
  -> IO(Unit):
  do IO<Unit>:
    lst : Listener <- server.listen(host, port)
    +slots : Chan(Unit) <- server.slots(max)
    +done : Chan(Unit) <- Chan.new(Unit, 1)
    server.forever.go(~C, handle, ctx, slots, Bool.not(U32.is_eq(max, 0)), done,
      lst)

# --- the text handlers (no context) ---

# a `_with` request as the text request a plain handler takes
def server.plain(r: Req) -> Http.Request:
  Req{method, target, headers, body, bytes} = r
  Http.Request{method, target, headers, body}

# a text reply as an answer
def server.text(reply: Http.Reply) -> IO(Answer):
  match reply:
    case Http.Torn{why}:
      IO.pure(Answer, TextReply{500, [], why})
    case Http.Reply{status, headers, body}:
      IO.pure(Answer, TextReply{status, headers, body})

# a plain IO handler as a `_with` one
def server.wrap.io(~handle: Http.Request -> IO(Http.Reply), r: Req)
  -> IO(Answer):
  IO.bind(Http.Reply, Answer, handle(server.plain(r)), server.text)

# listen and serve up to `limit` connections with an IO handler
def server.serve_io(~handle: Http.Request -> IO(Http.Reply), host: String,
  port: U32, limit: U32) -> IO(Unit):
  server.serve_io_with(~Unit, ~(_u => r => server.wrap.io(handle, r)), Unit{},
    host, port, limit, 0)

# a pure handler as an IO one
def server.lift(~handle: Http.Request -> Http.Reply, req: Http.Request)
  -> IO(Http.Reply):
  IO.pure(Http.Reply, handle(req))

# listen and serve up to `limit` connections
def server.serve(~handle: Http.Request -> Http.Reply, host: String, port: U32,
  limit: U32) -> IO(Unit):
  server.serve_io(~(req => server.lift(handle, req)), host, port, limit)

# serve exactly one connection then stop
def server.once(~handle: Http.Request -> Http.Reply, host: String, port: U32)
  -> IO(Unit):
  server.serve(handle, host, port, 1)

# listen and serve with an IO handler until the process is stopped
@unsafe def server.serve_forever(~handle: Http.Request -> IO(Http.Reply),
  host: String, port: U32) -> IO(Unit):
  server.serve_forever_with(~Unit, ~(_u => r => server.wrap.io(handle, r)), Unit{},
    host, port, 0)

# --- CORS (cors.bend), for pure handlers ---

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
def server.reply.text(~handle: Http.Request -> Http.Reply, req: Http.Request)
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
  Cors.cors.on(cfg, req, server.reply.text(handle, req))

