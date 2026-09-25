# Fair HTTP bench driver. Fixtures are loaded before IO.now. Timed loops stay
# in this process: GET/POST through ezhttp, and serve / serve_once for the
# server track. JSON cases call ezhttp/json.bend (ezjson). Core HTTP types
# stay text and octets.
import ../ezhttp/main.bend as Http
import ../ezhttp/http.bend as Msg
import ../ezhttp/body.bend as Body
import ../ezhttp/client.bend as Client
import ../ezhttp/json.bend as Json
import 0x81c67699424929b5c44cd8577e18117f/src/value.bend as V
import ./fix.bend as Fix

# unwrap a parsed U32, or zero when parse fails
def u32.arg.go(m: Maybe<&2, U32>) -> U32:
  match m:
    case Some{n}:
      n
    case None{}:
      0

# parse a decimal U32 from a string
def u32.arg(s: String) -> U32:
  u32.arg.go(U32.read(s))

# close the file once the write Result is Unit
def wrote.close(file: File, ok: Unit) -> IO(Unit):
  match ok:
    case Unit{}:
      File.close(file)

# force a write Result, then close the file
def wrote(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (file, result) = pair
  do IO<Unit>:
    ok : Unit <- IO.pass(Unit, result)
    wrote.close(file, ok)

# write a String to a path
def write.text(path: String, data: String) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, data)
    wrote(p)

# after reading text, close the file and return it
def took.after(s: String, closed: Unit) -> String:
  match closed:
    case Unit{}:
      s

# force a read Result, then close the file
def took.text(pair: File & Result<&1, &1, U32 & String, String>) -> IO(String):
  (file, result) = pair
  do IO<String>:
    s : String <- IO.pass(String, result)
    closed : Unit <- File.close(file)
    return took.after(s, closed)

# read n chars after learning the file size
def read.n(pair: File & Result<&1, &1, U32 & String, U32>) -> IO(String):
  (file, result) = pair
  do IO<String>:
    n : U32 <- IO.pass(U32, result)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(file, n)
    took.text(p)

# read a whole file as text (disk, outside the timers)
def read.text(path: String) -> IO(String):
  do IO<String>:
    f : File <- IO.try(File, File.open(path, "r"))
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    read.n(p)

# die with a message
def die.msg(msg: String) -> IO(Unit):
  IO.die(Unit, 1, msg)

# command plus three words; further words are ignored
def argv.w3(a: String, b: String, c: String, xs: List<String>) -> String & String & String & String:
  match xs:
    case Nil{}:
      (a, b, c, "")
    case d <> t:
      (a, b, c, d)

# third word
def argv.w2(a: String, b: String, xs: List<String>) -> String & String & String & String:
  match xs:
    case Nil{}:
      (a, b, "", "")
    case c <> t:
      argv.w3(a, b, c, t)

# second word
def argv.w1(a: String, xs: List<String>) -> String & String & String & String:
  match xs:
    case Nil{}:
      (a, "", "", "")
    case b <> t:
      argv.w2(a, b, t)

# split argv in one walk (the list is affine)
def argv.w0(xs: List<String>) -> String & String & String & String:
  match xs:
    case Nil{}:
      ("", "", "", "")
    case a <> t:
      argv.w1(a, t)

# plain text content type
def ctype.plain() -> String:
  "text/plain; charset=utf-8"

# octet content type
def ctype.bytes() -> String:
  "application/octet-stream"

# JSON content type
def ctype.json() -> String:
  "application/json"

# Content-Type header for text
def hdr.plain() -> Msg.Header:
  Msg.H{"Content-Type", ctype.plain()}

# Content-Type header for octets
def hdr.bytes() -> Msg.Header:
  Msg.H{"Content-Type", ctype.bytes()}

# Content-Type header for JSON
def hdr.json() -> Msg.Header:
  Msg.H{"Content-Type", ctype.json()}

# status line plus body, or ERR plus the reason
def show.resp(r: Client.Response) -> String:
  match r:
    case Client.Err{why}:
      "ERR\n" ++ why
    case Client.Response{status, headers, body}:
      U32.show(status) ++ "\n" ++ body

# one timing line: MS SUM BY N
def show.ms(t0: Nat, t1: Nat, +sum: U32, +bytes: U32, +n: U32) -> String:
  "MS " ++ Nat.show(Nat.sub(t1, t0)) ++ " SUM " ++ U32.show(sum) ++ " BY "
    ++ U32.show(bytes) ++ " N " ++ U32.show(n)

# prepend code points, then reverse once (tail walk)
def octets.go(s: String, acc: List<&2, U32>) -> List<&2, U32>:
  match s:
    case SNil{}:
      List.reverse(&2, U32, acc)
    case SCon{h, t}:
      octets.go(t, Char.to_u32(h) <> acc)

# octet list for an ASCII fixture
def octets.of(s: String) -> List<&2, U32>:
  octets.go(s, [])

# compact JSON text from a parsed value, or "" when it is not JSON
def json.out(m: Maybe<&2, V.Json>) -> String:
  match m:
    case None{}:
      ""
    case Some{j}:
      Body.body.payload(Json.json.body(j))

# 1 when parse fails, otherwise the printed length plus one
def json.touch.of(m: Maybe<&2, V.Json>) -> U32:
  match m:
    case None{}:
      1
    case Some{j}:
      (U32.from_nat(String.length(json.out(Some{j}))) + 1 : U32)

# print length of a parsed body, so the timed parse is used
def json.touch(body: String) -> U32:
  json.touch.of(Json.json.parse(body))

# fold a response into the checksum
def step.sum(+sum: U32, r: Client.Response) -> U32:
  match r:
    case Client.Err{why}:
      (sum + U32.from_nat(String.length(why)) + 1 : U32)
    case Client.Response{status, headers, body}:
      (sum + status + U32.from_nat(String.length(body)) : U32)

# fold a JSON response: status plus printed length
def step.json(+sum: U32, r: Client.Response) -> U32:
  match r:
    case Client.Err{why}:
      (sum + U32.from_nat(String.length(why)) + 1 : U32)
    case Client.Response{status, headers, body}:
      (sum + status + json.touch(body) : U32)

# add the bytes we sent so the encode is used
def step.sent(+sum: U32, r: Client.Response, sent: String) -> U32:
  (step.sum(sum, r) + U32.from_nat(String.length(sent)) : U32)

# repeat GET
def loop.get(+url: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      do IO<U32>:
        r : Client.Response <- Http.http.get(url)
        loop.get(url, p, step.sum(sum, r))

# repeat POST of a loaded text body
def loop.post(+url: String, +s: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      do IO<U32>:
        r : Client.Response <- Http.http.post_with(url, [hdr.plain()],
          Body.body.text(s))
        loop.post(url, s, p, step.sum(sum, r))

# repeat POST of an octet body built from the loaded text
def loop.bytes(+url: String, +s: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      do IO<U32>:
        r : Client.Response <- Http.http.post_with(url, [hdr.bytes()],
          Body.body.octets(octets.of(s)))
        loop.bytes(url, s, p, step.sum(sum, r))

# repeat GET plus JSON parse/print
def loop.get.json(+url: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      do IO<U32>:
        r : Client.Response <- Http.http.get(url)
        loop.get.json(url, p, step.json(sum, r))

# send one reprinted JSON body, then continue
def loop.post.json.send(url: String, sum: U32, +body: String, rest: U32 -> IO(U32)) -> IO(U32):
  do IO<U32>:
    r : Client.Response <- Http.http.post_with(url, [hdr.json()],
      Body.body.text(body))
    rest(step.sent(sum, r, body))

# parse failed: count it and continue
def loop.post.json.bad(sum: U32, rest: U32 -> IO(U32)) -> IO(U32):
  rest((sum + 1 : U32))

# one JSON POST step after parse
def loop.post.json.step(url: String, sum: U32, m: Maybe<&2, V.Json>, rest: U32 -> IO(U32)) -> IO(U32):
  match m:
    case None{}:
      loop.post.json.bad(sum, rest)
    case Some{j}:
      loop.post.json.send(url, sum, json.out(Some{j}), rest)

# repeat JSON parse, print, and POST
def loop.post.json(+url: String, +s: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      loop.post.json.step(url, sum, Json.json.parse(s),
        next => loop.post.json(url, s, p, next))

# print the timing line
def bench.show(t0: Nat, t1: Nat, +sum: U32, +bytes: U32, +n: U32) -> IO(Unit):
  IO.print(show.ms(t0, t1, sum, bytes, n))

# time N GETs; the URL is already known (no disk)
def bench.get(+url: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.get(url, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, 0, n)

# time the POSTs once the body is loaded
def bench.post.go(+url: String, +s: String, k: Nat, +n: U32) -> IO(Unit):
  +bytes = U32.from_nat(String.length(s))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.post(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

# time N text POSTs; the file is read before IO.now
def bench.post(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    bench.post.go(url, s, k, n)

# time the octet POSTs once the body is loaded
def bench.bytes.go(+url: String, +s: String, k: Nat, +n: U32) -> IO(Unit):
  +bytes = U32.from_nat(String.length(s))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.bytes(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

# time N octet POSTs; the file is read before IO.now
def bench.bytes(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    bench.bytes.go(url, s, k, n)

# time N JSON GETs (parse and print the response)
def bench.get.json(+url: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.get.json(url, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, 0, n)

# time the JSON POSTs once the file text is loaded
def bench.post.json.go(+url: String, +s: String, k: Nat, +n: U32) -> IO(Unit):
  +bytes = U32.from_nat(String.length(s))
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.post.json(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

# time N JSON POSTs; the file is read before IO.now
def bench.post.json(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    bench.post.json.go(url, s, k, n)

# one GET, write status and body
def cmd.get(url: String, dst: String) -> IO(Unit):
  do IO<Unit>:
    r : Client.Response <- Http.http.get(url)
    write.text(dst, show.resp(r))

# one text POST
def cmd.post(url: String, src: String, dst: String) -> IO(Unit):
  do IO<Unit>:
    s : String <- read.text(src)
    r : Client.Response <- Http.http.post_with(url, [hdr.plain()],
      Body.body.text(s))
    write.text(dst, show.resp(r))

# one octet POST
def cmd.bytes(url: String, src: String, dst: String) -> IO(Unit):
  do IO<Unit>:
    s : String <- read.text(src)
    r : Client.Response <- Http.http.post_with(url, [hdr.bytes()],
      Body.body.octets(octets.of(s)))
    write.text(dst, show.resp(r))

# POST the reprinted JSON
def cmd.post.json.send(url: String, dst: String, body: String) -> IO(Unit):
  do IO<Unit>:
    r : Client.Response <- Http.http.post_with(url, [hdr.json()],
      Body.body.text(body))
    write.text(dst, show.resp(r))

# die when the fixture is not JSON, otherwise POST its print
def cmd.post.json.go(url: String, dst: String, m: Maybe<&2, V.Json>) -> IO(Unit):
  match m:
    case None{}:
      die.msg("json parse failed")
    case Some{j}:
      cmd.post.json.send(url, dst, json.out(Some{j}))

# one JSON POST from a file
def cmd.post.json(url: String, src: String, dst: String) -> IO(Unit):
  do IO<Unit>:
    s : String <- read.text(src)
    cmd.post.json.go(url, dst, Json.json.parse(s))

# write compact JSON or die
def cmd.json.ok.go(dst: String, m: Maybe<&2, V.Json>) -> IO(Unit):
  match m:
    case None{}:
      die.msg("json parse failed")
    case Some{j}:
      write.text(dst, json.out(Some{j}))

# parse a file with the shipped JSON helper and write the print
def cmd.json.ok(src: String, dst: String) -> IO(Unit):
  do IO<Unit>:
    s : String <- read.text(src)
    cmd.json.ok.go(dst, Json.json.parse(s))

# 200 with a content type and a fixed body
def reply.ok(ctype: String, body: String) -> Msg.Reply:
  Msg.Reply{200, [Msg.H{"Content-Type", ctype}], body}

# 200 echoing the request body
def reply.echo(ctype: String, body: String) -> Msg.Reply:
  Msg.Reply{200, [Msg.H{"Content-Type", ctype}], body}

# 400 when the body is not JSON
def reply.json.bad() -> Msg.Reply:
  Msg.Reply{400, [], "bad json"}

# reprint JSON, or 400
def reply.json.of(m: Maybe<&2, V.Json>) -> Msg.Reply:
  match m:
    case None{}:
      reply.json.bad()
    case Some{j}:
      reply.ok(ctype.json(), json.out(Some{j}))

# POST /json: parse with ezhttp/json.bend and answer with the print
def reply.json(body: String) -> Msg.Reply:
  reply.json.of(Json.json.parse(body))

# 404 for an unknown target
def route.miss() -> Msg.Reply:
  Msg.Reply{404, [], "missing"}

# pick a reply after the comparison is bound
def on.reply(z: Bool, yes: Unit -> Msg.Reply, no: Unit -> Msg.Reply) -> Msg.Reply:
  match z:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

# pick an IO action after the comparison is bound
def on.io(z: Bool, yes: Unit -> IO(Unit), no: Unit -> IO(Unit)) -> IO(Unit):
  match z:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

# GET /json/medium or 404
def route.get.medium(target: String, medium: String) -> Msg.Reply:
  on.reply(String.eq(target, "/json/medium"),
    _u => reply.ok(ctype.json(), medium),
    _u => route.miss())

# GET /json/small, else medium
def route.get.small(+target: String, small: String, medium: String) -> Msg.Reply:
  on.reply(String.eq(target, "/json/small"),
    _u => reply.ok(ctype.json(), small),
    _u => route.get.medium(target, medium))

# GET /bytes, else JSON
def route.get.bytes(+target: String, raw: String, small: String, medium: String) -> Msg.Reply:
  on.reply(String.eq(target, "/bytes"),
    _u => reply.ok(ctype.bytes(), raw),
    _u => route.get.small(target, small, medium))

# GET fixed fixtures
def route.get(+target: String, text: String, raw: String, small: String, medium: String) -> Msg.Reply:
  on.reply(String.eq(target, "/text"),
    _u => reply.ok(ctype.plain(), text),
    _u => route.get.bytes(target, raw, small, medium))

# POST /json/medium parses; anything else is 404
def route.post.medium(target: String, body: String) -> Msg.Reply:
  on.reply(String.eq(target, "/json/medium"),
    _u => reply.json(body),
    _u => route.miss())

# POST /json/small parses; else medium
def route.post.small(+target: String, +body: String) -> Msg.Reply:
  on.reply(String.eq(target, "/json/small"),
    _u => reply.json(body),
    _u => route.post.medium(target, body))

# POST /bytes echoes the body
def route.post.bytes(+target: String, +body: String) -> Msg.Reply:
  on.reply(String.eq(target, "/bytes"),
    _u => reply.echo(ctype.bytes(), body),
    _u => route.post.small(target, body))

# POST /text echoes; JSON routes parse
def route.post(+target: String, +body: String) -> Msg.Reply:
  on.reply(String.eq(target, "/text"),
    _u => reply.echo(ctype.plain(), body),
    _u => route.post.bytes(target, body))

# POST or 405
def handle.post(method: String, target: String, body: String) -> Msg.Reply:
  on.reply(String.eq(method, "POST"),
    _u => route.post(target, body),
    _u => Msg.Reply{405, [], "method"})

# GET fixed responses, POST echo or JSON print
def handle.method(
  +method: String,
  +target: String,
  body: String,
  text: String,
  raw: String,
  small: String,
  medium: String
) -> Msg.Reply:
  on.reply(String.eq(method, "GET"),
    _u => route.get(target, text, raw, small, medium),
    _u => handle.post(method, target, body))

# route one request using fixture strings passed in
def handle.req(req: Msg.Request, text: String, raw: String, small: String, medium: String) -> Msg.Reply:
  match req:
    case Msg.Bad{why}:
      Msg.Reply{400, [], why}
    case Msg.Request{method, target, headers, body}:
      handle.method(method, target, body, text, raw, small, medium)

# pure handler: fixtures are closed literals, not captured runtime values
def handle(req: Msg.Request) -> Msg.Reply:
  handle.req(req, Fix.fix.text(), Fix.fix.bytes(), Fix.fix.small(), Fix.fix.medium())

# listen; the handler is closed, so fixtures stay in the binary
def serve.go(port: U32, limit: U32) -> IO(Unit):
  Http.http.serve(handle, port, limit)

# one connection, then stop
def once.go(port: U32) -> IO(Unit):
  Http.http.serve_once(handle, port)

# serve port limit
def run.serve(+cmd: String, a1: String, a2: String) -> IO(Unit):
  on.io(String.eq(cmd, "serve"),
    _u => serve.go(u32.arg(a1), u32.arg(a2)),
    _u => die.msg("unknown command " ++ cmd))

# serve-once port
def run.once(+cmd: String, +a1: String, a2: String) -> IO(Unit):
  on.io(String.eq(cmd, "serve-once"),
    _u => once.go(u32.arg(a1)),
    _u => run.serve(cmd, a1, a2))

# bench-post url src n
def run.bpost(+cmd: String, +a1: String, +a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "bench-post"),
    _u => bench.post(a1, a2, u32.arg(a3)),
    _u => run.once(cmd, a1, a2))

# bench-post-json url src n
def run.bpjson(+cmd: String, +a1: String, +a2: String, +a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "bench-post-json"),
    _u => bench.post.json(a1, a2, u32.arg(a3)),
    _u => run.bpost(cmd, a1, a2, a3))

# bench-post-bytes url src n
def run.bbytes(+cmd: String, +a1: String, +a2: String, +a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "bench-post-bytes"),
    _u => bench.bytes(a1, a2, u32.arg(a3)),
    _u => run.bpjson(cmd, a1, a2, a3))

# bench-get url n
def run.bget(+cmd: String, +a1: String, +a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "bench-get"),
    _u => bench.get(a1, u32.arg(a2)),
    _u => run.bbytes(cmd, a1, a2, a3))

# bench-get-json url n
def run.bgetj(+cmd: String, +a1: String, +a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "bench-get-json"),
    _u => bench.get.json(a1, u32.arg(a2)),
    _u => run.bget(cmd, a1, a2, a3))

# post url src dst
def run.post(+cmd: String, +a1: String, +a2: String, +a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "post"),
    _u => cmd.post(a1, a2, a3),
    _u => run.bgetj(cmd, a1, a2, a3))

# post-json url src dst
def run.pjson(+cmd: String, +a1: String, +a2: String, +a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "post-json"),
    _u => cmd.post.json(a1, a2, a3),
    _u => run.post(cmd, a1, a2, a3))

# post-bytes url src dst
def run.bytes(+cmd: String, +a1: String, +a2: String, +a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "post-bytes"),
    _u => cmd.bytes(a1, a2, a3),
    _u => run.pjson(cmd, a1, a2, a3))

# get url dst
def run.get(+cmd: String, +a1: String, +a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "get"),
    _u => cmd.get(a1, a2),
    _u => run.bytes(cmd, a1, a2, a3))

# json-ok src dst
def run.json(+cmd: String, +a1: String, +a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "json-ok"),
    _u => cmd.json.ok(a1, a2),
    _u => run.get(cmd, a1, a2, a3))

# ping
def run.ping(+cmd: String, a1: String, a2: String, a3: String) -> IO(Unit):
  on.io(String.eq(cmd, "ping"),
    _u => IO.print("pong"),
    _u => run.json(cmd, a1, a2, a3))

# run once the four words are a parameter
def main.go.un(quad: String & String & String & String) -> IO(Unit):
  (cmd, a1, a2, a3) = quad
  run.ping(cmd, a1, a2, a3)

# unpack argv and run the named command
def main.go(args: List<String>) -> IO(Unit):
  main.go.un(argv.w0(args))

# CLI entry
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    main.go(args)
