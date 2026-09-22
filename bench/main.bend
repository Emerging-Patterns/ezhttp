# Fair HTTP bench driver. Fixtures are loaded before IO.now. Timed loops stay
# in this process: GET/POST through ezhttp, and serve / serve_once for the
# server track. JSON cases call ezhttp/json.bend (ezjson). Core HTTP types
# stay text and octets.
import ../ezhttp/main.bend as Http
import ../ezhttp/http.bend as Msg
import ../ezhttp/body.bend as Body
import ../ezhttp/client.bend as Client
import ../ezhttp/json.bend as Json
import 0xce326a73bca73cdb726972cee5bd76d4/value.bend as V

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

# the nth argv word, "" when the list is shorter
def arg.nth.step(here: Bool, h: String, t: List<String>, i: Nat) -> String:
  match here:
    case True{}:
      h
    case False{}:
      arg.nth(t, Nat.sub(i, 1n))

# walk argv to the index
def arg.nth(xs: List<String>, i: Nat) -> String:
  match xs:
    case Nil{}:
      ""
    case h <> t:
      arg.nth.step(Nat.is_eq(i, 0n), h, t, i)

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

# print length of a parsed body, so the timed parse is used
def json.touch(body: String) -> U32:
  json.touch.of(Json.json.parse(body))

# 1 when parse fails, otherwise the printed length plus one
def json.touch.of(m: Maybe<&2, V.Json>) -> U32:
  match m:
    case None{}:
      1
    case Some{j}:
      (U32.from_nat(String.length(json.out(Some{j}))) + 1 : U32)

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
def loop.post.json.send(+url: String, +s: String, n: Nat, +sum: U32, +body: String) -> IO(U32):
  do IO<U32>:
    r : Client.Response <- Http.http.post_with(url, [hdr.json()],
      Body.body.text(body))
    loop.post.json(url, s, n, step.sent(sum, r, body))

# parse failed: count it and continue
def loop.post.json.bad(+url: String, +s: String, n: Nat, +sum: U32) -> IO(U32):
  loop.post.json(url, s, n, (sum + 1 : U32))

# one JSON POST step after parse
def loop.post.json.step(+url: String, +s: String, n: Nat, +sum: U32, m: Maybe<&2, V.Json>) -> IO(U32):
  match m:
    case None{}:
      loop.post.json.bad(url, s, n, sum)
    case Some{j}:
      loop.post.json.send(url, s, n, sum, json.out(Some{j}))

# repeat JSON parse, print, and POST
def loop.post.json(+url: String, +s: String, n: Nat, +sum: U32) -> IO(U32):
  match n:
    case 0n:
      IO.pure(U32, sum)
    case 1n+p:
      loop.post.json.step(url, s, p, sum, Json.json.parse(s))

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

# time N text POSTs; the file is read before IO.now
def bench.post(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    +bytes = U32.from_nat(String.length(s))
    t0 : Nat <- IO.now()
    sum : U32 <- loop.post(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

# time N octet POSTs; the file is read before IO.now
def bench.bytes(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    +bytes = U32.from_nat(String.length(s))
    t0 : Nat <- IO.now()
    sum : U32 <- loop.bytes(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

# time N JSON GETs (parse and print the response)
def bench.get.json(+url: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    sum : U32 <- loop.get.json(url, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, 0, n)

# time N JSON POSTs; the file is read before IO.now
def bench.post.json(+url: String, path: String, +n: U32) -> IO(Unit):
  +k = U32.to_nat(n)
  do IO<Unit>:
    s : String <- read.text(path)
    +bytes = U32.from_nat(String.length(s))
    t0 : Nat <- IO.now()
    sum : U32 <- loop.post.json(url, s, k, 0)
    t1 : Nat <- IO.now()
    bench.show(t0, t1, sum, bytes, n)

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

# GET /json/medium or 404
def route.get.medium(target: String, medium: String) -> Msg.Reply:
  match String.eq(target, "/json/medium"):
    case True{}:
      reply.ok(ctype.json(), medium)
    case False{}:
      route.miss()

# GET /json/small, else medium
def route.get.small(target: String, small: String, medium: String) -> Msg.Reply:
  match String.eq(target, "/json/small"):
    case True{}:
      reply.ok(ctype.json(), small)
    case False{}:
      route.get.medium(target, medium)

# GET /bytes, else JSON
def route.get.bytes(target: String, raw: String, small: String, medium: String) -> Msg.Reply:
  match String.eq(target, "/bytes"):
    case True{}:
      reply.ok(ctype.bytes(), raw)
    case False{}:
      route.get.small(target, small, medium)

# GET fixed fixtures
def route.get(target: String, text: String, raw: String, small: String, medium: String) -> Msg.Reply:
  match String.eq(target, "/text"):
    case True{}:
      reply.ok(ctype.plain(), text)
    case False{}:
      route.get.bytes(target, raw, small, medium)

# POST /json/medium parses; anything else is 404
def route.post.medium(target: String, body: String) -> Msg.Reply:
  match String.eq(target, "/json/medium"):
    case True{}:
      reply.json(body)
    case False{}:
      route.miss()

# POST /json/small parses; else medium
def route.post.small(target: String, body: String) -> Msg.Reply:
  match String.eq(target, "/json/small"):
    case True{}:
      reply.json(body)
    case False{}:
      route.post.medium(target, body)

# POST /bytes echoes the body
def route.post.bytes(target: String, body: String) -> Msg.Reply:
  match String.eq(target, "/bytes"):
    case True{}:
      reply.echo(ctype.bytes(), body)
    case False{}:
      route.post.small(target, body)

# POST /text echoes; JSON routes parse
def route.post(target: String, body: String) -> Msg.Reply:
  match String.eq(target, "/text"):
    case True{}:
      reply.echo(ctype.plain(), body)
    case False{}:
      route.post.bytes(target, body)

# POST or 405
def handle.post(method: String, target: String, body: String) -> Msg.Reply:
  match String.eq(method, "POST"):
    case True{}:
      route.post(target, body)
    case False{}:
      Msg.Reply{405, [], "method"}

# GET fixed responses, POST echo or JSON print
def handle.method(
  method: String,
  target: String,
  body: String,
  text: String,
  raw: String,
  small: String,
  medium: String
) -> Msg.Reply:
  match String.eq(method, "GET"):
    case True{}:
      route.get(target, text, raw, small, medium)
    case False{}:
      handle.post(method, target, body)

# handler closed over the fixtures loaded before listen
def handle.req(req: Msg.Request, text: String, raw: String, small: String, medium: String) -> Msg.Reply:
  match req:
    case Msg.Bad{why}:
      Msg.Reply{400, [], why}
    case Msg.Request{method, target, headers, body}:
      handle.method(method, target, body, text, raw, small, medium)

# listen with the loaded fixtures
def serve.go(port: U32, limit: U32, text: String, raw: String, small: String, medium: String) -> IO(Unit):
  Http.http.serve(req => handle.req(req, text, raw, small, medium), port, limit)

# read fixtures, then serve up to limit connections
def serve.load(port: U32, limit: U32, tp: String, bp: String, sp: String, mp: String) -> IO(Unit):
  do IO<Unit>:
    text : String <- read.text(tp)
    raw : String <- read.text(bp)
    small : String <- read.text(sp)
    medium : String <- read.text(mp)
    serve.go(port, limit, text, raw, small, medium)

# one connection, then stop
def once.go(port: U32, text: String, raw: String, small: String, medium: String) -> IO(Unit):
  Http.http.serve_once(req => handle.req(req, text, raw, small, medium), port)

# read fixtures, then serve_once
def once.load(port: U32, tp: String, bp: String, sp: String, mp: String) -> IO(Unit):
  do IO<Unit>:
    text : String <- read.text(tp)
    raw : String <- read.text(bp)
    small : String <- read.text(sp)
    medium : String <- read.text(mp)
    once.go(port, text, raw, small, medium)

# ping
def run.ping(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "ping"):
    case True{}:
      IO.print("pong")
    case False{}:
      run.json(cmd, args)

# json-ok src dst
def run.json(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "json-ok"):
    case True{}:
      cmd.json.ok(arg.nth(args, 1n), arg.nth(args, 2n))
    case False{}:
      run.get(cmd, args)

# get url dst
def run.get(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "get"):
    case True{}:
      cmd.get(arg.nth(args, 1n), arg.nth(args, 2n))
    case False{}:
      run.bytes(cmd, args)

# post-bytes url src dst
def run.bytes(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "post-bytes"):
    case True{}:
      cmd.bytes(arg.nth(args, 1n), arg.nth(args, 2n), arg.nth(args, 3n))
    case False{}:
      run.pjson(cmd, args)

# post-json url src dst
def run.pjson(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "post-json"):
    case True{}:
      cmd.post.json(arg.nth(args, 1n), arg.nth(args, 2n), arg.nth(args, 3n))
    case False{}:
      run.post(cmd, args)

# post url src dst
def run.post(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "post"):
    case True{}:
      cmd.post(arg.nth(args, 1n), arg.nth(args, 2n), arg.nth(args, 3n))
    case False{}:
      run.bgetj(cmd, args)

# bench-get-json url n
def run.bgetj(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "bench-get-json"):
    case True{}:
      bench.get.json(arg.nth(args, 1n), u32.arg(arg.nth(args, 2n)))
    case False{}:
      run.bget(cmd, args)

# bench-get url n
def run.bget(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "bench-get"):
    case True{}:
      bench.get(arg.nth(args, 1n), u32.arg(arg.nth(args, 2n)))
    case False{}:
      run.bbytes(cmd, args)

# bench-post-bytes url src n
def run.bbytes(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "bench-post-bytes"):
    case True{}:
      bench.bytes(arg.nth(args, 1n), arg.nth(args, 2n), u32.arg(arg.nth(args, 3n)))
    case False{}:
      run.bpjson(cmd, args)

# bench-post-json url src n
def run.bpjson(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "bench-post-json"):
    case True{}:
      bench.post.json(arg.nth(args, 1n), arg.nth(args, 2n),
        u32.arg(arg.nth(args, 3n)))
    case False{}:
      run.bpost(cmd, args)

# bench-post url src n
def run.bpost(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "bench-post"):
    case True{}:
      bench.post(arg.nth(args, 1n), arg.nth(args, 2n), u32.arg(arg.nth(args, 3n)))
    case False{}:
      run.once(cmd, args)

# serve-once port text bytes small medium
def run.once(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "serve-once"):
    case True{}:
      once.load(u32.arg(arg.nth(args, 1n)), arg.nth(args, 2n), arg.nth(args, 3n),
        arg.nth(args, 4n), arg.nth(args, 5n))
    case False{}:
      run.serve(cmd, args)

# serve port limit text bytes small medium
def run.serve(cmd: String, args: List<String>) -> IO(Unit):
  match String.eq(cmd, "serve"):
    case True{}:
      serve.load(u32.arg(arg.nth(args, 1n)), u32.arg(arg.nth(args, 2n)),
        arg.nth(args, 3n), arg.nth(args, 4n), arg.nth(args, 5n),
        arg.nth(args, 6n))
    case False{}:
      die.msg("unknown command " ++ cmd)

# unpack argv and run the named command
def main.go(args: List<String>) -> IO(Unit):
  run.ping(arg.nth(args, 0n), args)

# CLI entry
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    main.go(args)
