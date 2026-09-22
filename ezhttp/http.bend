# ezhttp/http: HTTP/1.1 message text for client and server — request and
# response formatting/parsing — with no sockets. Semantics follow RFC 9110;
# message syntax and framing follow RFC 9112. TLS is outside this module.
import Base
import ./body.bend as Body

# a string divided at the first occurrence of a pattern, or not divided at all
type Cut is Data:
  NoCut{}
  Cut{before: String, after: String}

# one header field name and value (RFC 9110 §5 / RFC 9112 §5)
type Header is Data:
  H{name: String, value: String}

# what a response turned out to be: status, headers, framed body — or why not
type Reply is Data:
  Torn{why: String}
  Reply{status: U32, headers: List<&2, Header>, body: String}

# the first of a list of pieces, "" when there are none
def first(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case h <> t:
      h

# the second of a list of pieces, "" when there is no second
def second(ps: List<&2, String>) -> String:
  match ps:
    case []:
      ""
    case h <> t:
      first(t)

# one char of the divide, put back on the front of what the rest found
def divide.push(h: Char, r: Cut) -> Cut:
  match r:
    case NoCut{}:
      NoCut{}
    case Cut{before, after}:
      Cut{SCon{h, before}, after}

# one step of the walk; rest is a thunk so Bool.pick does not force recursion
def divide.step(here: Bool, h: Char, t: String, n: Nat,
  rest: Unit -> Cut) -> Cut:
  match here:
    case True{}:
      Cut{"", String.drop(SCon{h, t}, n)}
    case False{}:
      divide.push(h, rest(Unit{}))

# the walk: stop at the first hit
def divide.go(s: String, +pat: String, +n: Nat) -> Cut:
  match s:
    case SNil{}:
      NoCut{}
    case SCon{+h, +t}:
      divide.step(String.starts_with(SCon{h, t}, pat), h, t, n,
        _u => divide.go(t, pat, n))

# a string in two halves around the first occurrence of a pattern
def divide(s: String, +pat: String) -> Cut:
  divide.go(s, pat, String.length(pat))

# the value of one hex digit's code point, or 16 when it is not one
def hex.of(+u: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)), U32.sub(u, 48),
    Bool.pick(U32, Bool.and(U32.is_ge(u, 97), U32.is_le(u, 102)), U32.sub(u, 87),
      Bool.pick(U32, Bool.and(U32.is_ge(u, 65), U32.is_le(u, 70)), U32.sub(u, 55),
        16)))

# the value of one hex digit, or 16 when the char is not one
def hex.val(c: Char) -> U32:
  hex.of(Char.to_u32(c))

# one step of the hex read
def hex.step(done: Bool, acc: Nat, rest: Unit -> Nat) -> Nat:
  match done:
    case True{}:
      acc
    case False{}:
      rest(Unit{})

# the hex digits at the front of a string, read until one is not a digit
def hex.go(s: String, +acc: Nat) -> Nat:
  match s:
    case SNil{}:
      acc
    case SCon{+h, t}:
      +v = hex.val(h)
      hex.step(U32.is_ge(v, 16), acc,
        _u => hex.go(t, Nat.add(Nat.mul(acc, 16n), U32.to_nat(v))))

# chunk-size from a chunk header (RFC 9112 §7.1); extensions after `;` ignored
def hexlen(s: String) -> Nat:
  hex.go(String.trim(first(String.split(s, ';'))), 0n)

# whether a character is a hex digit
def hex.digit(c: Char) -> Bool:
  U32.is_lt(hex.val(c), 16)

# the rest of a hex token once the first digit is known
def hex.rest(token: String, good: Bool) -> Bool:
  match token good:
    case _ False{}:
      False{}
    case SNil{} True{}:
      True{}
    case SCon{h, t} True{}:
      hex.rest(t, hex.digit(h))

# a chunk-size token is one or more hex digits (RFC 9112 §7.1)
def hex.well(token: String) -> Bool:
  match token:
    case SNil{}:
      False{}
    case SCon{h, t}:
      hex.rest(t, hex.digit(h))

# the chunk-size token, extensions after `;` removed
def chunks.token(before: String) -> String:
  String.trim(first(String.split(before, ';')))

# bytes one code point takes in UTF-8. Content-Length counts octets
# (RFC 9110 §8.6); a Bend String counts code points.
def utf8.width(+u: U32) -> Nat:
  Bool.pick(Nat, U32.is_lt(u, 128), 1n,
    Bool.pick(Nat, U32.is_lt(u, 2048), 2n,
      Bool.pick(Nat, U32.is_lt(u, 65536), 3n, 4n)))

# how many bytes of UTF-8 a string is
def utf8.len(s: String) -> Nat:
  match s:
    case SNil{}:
      0n
    case SCon{h, t}:
      Nat.add(utf8.width(Char.to_u32(h)), utf8.len(t))

# one step of the take
def utf8.take.step(short: Bool, h: Char, rest: Unit -> String) -> String:
  match short:
    case True{}:
      SNil{}
    case False{}:
      SCon{h, rest(Unit{})}

# the front of a string that is this many bytes of UTF-8
def utf8.take(s: String, +n: Nat) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+h, t}:
      +w = utf8.width(Char.to_u32(h))
      utf8.take.step(Nat.is_lt(n, w), h, _u => utf8.take(t, Nat.sub(n, w)))

# one step of the drop
def utf8.drop.step(short: Bool, h: Char, t: String,
  rest: Unit -> String) -> String:
  match short:
    case True{}:
      SCon{h, t}
    case False{}:
      rest(Unit{})

# the rest of a string after this many bytes of UTF-8
def utf8.drop(s: String, +n: Nat) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{+h, +t}:
      +w = utf8.width(Char.to_u32(h))
      utf8.drop.step(Nat.is_lt(n, w), h, t, _u => utf8.drop(t, Nat.sub(n, w)))

# a decimal digit's value, or 10 when the character is not a digit
def digits.val.of(+u: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)), U32.sub(u, 48), 10)

# a decimal digit's value, or 10 when the character is not a digit
def digits.val(c: Char) -> U32:
  digits.val.of(Char.to_u32(c))

# accept one digit and keep reading, or stop when it is not a digit
def digits.step(ok: Bool, next: Unit -> Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match ok:
    case False{}:
      None{}
    case True{}:
      next(Unit{})

# read a decimal token without building Base's Nat.read ceiling
def digits.go(s: String, +acc: Nat, left: Nat) -> Maybe<&2, Nat>:
  match s left:
    case _ 0n:
      None{}
    case SNil{} 1n+k:
      Some{acc}
    case SCon{+h, t} 1n+k:
      +d = digits.val(h)
      digits.step(U32.is_lt(d, 10),
        _u => digits.go(t, Nat.add(Nat.mul(acc, 10n), U32.to_nat(d)), k))

# a short decimal (Content-Length, max-age). Empty is none. At most 9 digits.
def digits.read(s: String) -> Maybe<&2, Nat>:
  match s:
    case SNil{}:
      None{}
    case SCon{h, t}:
      digits.go(SCon{h, t}, 0n, 9n)

# a non-zero chunk has its data and the following CRLF
def chunks.ready(+after: String, +n: Nat) -> Bool:
  Bool.and(Bool.not(Nat.is_lt(utf8.len(after), Nat.add(n, 2n))),
    String.starts_with(utf8.drop(after, n), "\r\n"))

# the next scan step, or why this chunk header is not usable
type Next is Data:
  Stop{}
  Go{cut: Cut}
  Reject{why: String}

# one chunk header: reject non-hex sizes, stop on the 0 chunk, else continue
def chunks.next.of(zero: Bool, ready: Bool, +after: String, +n: Nat) -> Next:
  match zero ready:
    case True{} _:
      Stop{}
    case False{} False{}:
      Reject{"the chunked body stopped short"}
    case False{} True{}:
      Go{divide(utf8.drop(after, Nat.add(n, 2n)), "\r\n")}

# hex check, then the length
def chunks.next.hex(+before: String, +after: String, ok: Bool) -> Next:
  match ok:
    case False{}:
      Reject{"chunk size is not hexadecimal"}
    case True{}:
      +n = hexlen(before)
      chunks.next.of(Nat.is_eq(n, 0n), chunks.ready(after, n), after, n)

# classify one chunk header (RFC 9112 §7.1)
def chunks.next(+before: String, +after: String) -> Next:
  chunks.next.hex(before, after, hex.well(chunks.token(before)))

# apply one scan step
def chunks.scan.step(step: Next, rest: Cut -> Maybe<&2, String>)
  -> Maybe<&2, String>:
  match step:
    case Stop{}:
      None{}
    case Reject{why}:
      Some{why}
    case Go{cut}:
      rest(cut)

# None when every chunk size is hex and the 0 chunk is reached
def chunks.scan(fuel: Nat, c: Cut) -> Maybe<&2, String>:
  match fuel c:
    case 0n _:
      Some{"the chunked body is truncated"}
    case 1n+f NoCut{}:
      None{}
    case 1n+f Cut{before, +after}:
      chunks.scan.step(chunks.next(before, after), cut => chunks.scan(f, cut))

# a chunked body put back together (RFC 9112 §7.1)
def chunks(fuel: Nat, c: Cut) -> String:
  match fuel c:
    case 0n _:
      ""
    case 1n+f NoCut{}:
      ""
    case 1n+f Cut{before, +after}:
      +n = hexlen(before)
      utf8.take(after, n)
        ++ chunks(f, divide(utf8.drop(after, Nat.add(n, 2n)), "\r\n"))

# a Transfer-Encoding: chunked body as the octets it stands for
def dechunk(+s: String) -> String:
  chunks(String.length(s), divide(s, "\r\n"))

# whether a head line names this header (field names are case-insensitive:
# RFC 9110 §5.1)
def head.hit(h: String, +name: String) -> Bool:
  String.starts_with(String.to_lower(h), name ++ ":")

# this line's value when it is the header asked for
def head.pick(hit: Bool, h: String, name: String, rest: String) -> String:
  match hit:
    case True{}:
      String.trim(String.drop(h, Nat.add(String.length(name), 1n)))
    case False{}:
      rest

# the value a head gave a header, "" when it gave none
def head.go(ls: List<&2, String>, +name: String) -> String:
  match ls:
    case []:
      ""
    case +h <> t:
      head.pick(head.hit(h, name), h, name, head.go(t, name))

# this line's trimmed field value
def head.value(h: String, name: String) -> String:
  String.trim(String.drop(h, Nat.add(String.length(name), 1n)))

# cons a value when the line is the header asked for
def head.values.cons(hit: Bool, value: String, rest: Unit -> List<&2, String>)
  -> List<&2, String>:
  match hit:
    case False{}:
      rest(Unit{})
    case True{}:
      value <> rest(Unit{})

# every value a head gave a header, in order (RFC 9112 §6.3 lists Content-Length)
def head.values(ls: List<&2, String>, +name: String) -> List<&2, String>:
  match ls:
    case []:
      []
    case +h <> t:
      head.values.cons(head.hit(h, name), head.value(h, name),
        _u => head.values(t, name))

# a field value still holding a line break is obs-fold, which we refuse
def field.folded(+value: String) -> Bool:
  Bool.or(String.contains(value, "\n"), String.contains(value, "\r"))

# a trimmed field value, or none when it still contains obs-fold
def field.keep(name: String, +value: String, folded: Bool) -> Maybe<&2, Header>:
  match folded:
    case True{}:
      None{}
    case False{}:
      Some{H{name, value}}

# name and trimmed value from a cut at the first colon
def head.from_kept(before: String, +after: String) -> Maybe<&2, Header>:
  +value = String.trim(after)
  field.keep(before, value, field.folded(value))

# one header line as a Header, or none when it has no colon
def head.from_cut(c: Cut) -> Maybe<&2, Header>:
  match c:
    case NoCut{}:
      None{}
    case Cut{before, after}:
      head.from_kept(before, after)

# one header line as a Header, or none when it has no colon
def head.line(h: String) -> Maybe<&2, Header>:
  head.from_cut(divide(h, ":"))

# prepend a parsed header when present
def head.cons(m: Maybe<&2, Header>, rest: List<&2, Header>) -> List<&2, Header>:
  match m:
    case None{}:
      rest
    case Some{hdr}:
      hdr <> rest

# header lines after the status line as a list of fields
def head.list(ls: List<&2, String>) -> List<&2, Header>:
  match ls:
    case []:
      []
    case h <> t:
      head.cons(head.line(h), head.list(t))

# one request header line
def header.line(h: Header) -> String:
  match h:
    case H{name, value}:
      name ++ ": " ++ value ++ "\r\n"

# the value when this field is the one asked for
def headers.find.pick(value: String, hit: Bool, rest: Unit -> String) -> String:
  match hit:
    case True{}:
      value
    case False{}:
      rest(Unit{})

# case-insensitive field lookup (RFC 9110 §5.1)
def headers.find.go(hs: List<&2, Header>, +name: String) -> String:
  match hs:
    case []:
      ""
    case H{n, v} <> t:
      headers.find.pick(v, String.eq(String.to_lower(n), name),
        _u => headers.find.go(t, name))

# the value of a field, "" when it is absent
def headers.find(hs: List<&2, Header>, +name: String) -> String:
  headers.find.go(hs, String.to_lower(name))

# extra headers rendered in order
def headers.lines(hs: List<&2, Header>) -> String:
  match hs:
    case []:
      ""
    case h <> t:
      header.line(h) ++ headers.lines(t)

# Content-Length line when the body is not empty (RFC 9110 §8.6)
def clen.line(+n: Nat, empty: Bool) -> String:
  match empty:
    case True{}:
      ""
    case False{}:
      "Content-Length: " ++ Nat.show(n) ++ "\r\n"

# a request-line and headers (RFC 9112 §3, §5). Absolute-path request-target
# (RFC 9112 §3.2.1). Connection: close so the connection end frames the body
# when no Content-Length / chunked framing applies (RFC 9112 §9.6 / §6.3).
def request(method: String, host: String, path: String,
  headers: List<&2, Header>, +body: String) -> String:
  +n = utf8.len(body)
  method ++ " " ++ path ++ " HTTP/1.1\r\n"
    ++ "Host: " ++ host ++ "\r\n"
    ++ "User-Agent: ezhttp\r\n"
    ++ "Accept: */*\r\n"
    ++ "Connection: close\r\n"
    ++ headers.lines(headers)
    ++ clen.line(n, Nat.is_eq(n, 0n))
    ++ "\r\n"
    ++ body

# GET with optional headers
def get_req(host: String, path: String, headers: List<&2, Header>) -> String:
  request("GET", host, path, headers, "")

# HEAD with optional headers (RFC 9110 §9.3.2): same as GET, no body
def head_req(host: String, path: String, headers: List<&2, Header>) -> String:
  request("HEAD", host, path, headers, "")

# POST with body and optional headers
def post_req(host: String, path: String, headers: List<&2, Header>,
  body: Body.Body) -> String:
  request("POST", host, path, headers, Body.body.payload(body))

# PUT with body and optional headers (RFC 9110 §9.3.4)
def put_req(host: String, path: String, headers: List<&2, Header>,
  body: Body.Body) -> String:
  request("PUT", host, path, headers, Body.body.payload(body))

# DELETE with body and optional headers (RFC 9110 §9.3.5)
def delete_req(host: String, path: String, headers: List<&2, Header>,
  body: Body.Body) -> String:
  request("DELETE", host, path, headers, Body.body.payload(body))

# OPTIONS with optional headers (RFC 9110 §9.3.7). No request body.
def options_req(host: String, path: String, headers: List<&2, Header>) -> String:
  request("OPTIONS", host, path, headers, "")

# GET, HEAD, and OPTIONS are safe (RFC 9110 §9.2.1). Tokens are case-sensitive.
def method.safe(+method: String) -> Bool:
  Bool.or(String.eq(method, "GET"),
    Bool.or(String.eq(method, "HEAD"), String.eq(method, "OPTIONS")))

# safe methods, plus PUT and DELETE, are idempotent (RFC 9110 §9.2.2)
def method.idempotent(+method: String) -> Bool:
  Bool.or(method.safe(method),
    Bool.or(String.eq(method, "PUT"), String.eq(method, "DELETE")))

# the rest of a token once this character is known
def token.ok.step(space: Bool, rest: Unit -> Bool) -> Bool:
  match space:
    case True{}:
      False{}
    case False{}:
      rest(Unit{})

# a bearer token has no whitespace (RFC 6750 §2.1)
def token.ok(s: String) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{h, t}:
      token.ok.step(Char.is_space(h), _u => token.ok(t))

# origin-form request-target: absolute-path, optional query (RFC 9112 §3.2.1)
def target.origin(path: String) -> Bool:
  String.starts_with(path, "/")

# a body against the length its head promised
def parse.short(status: U32, headers: List<&2, Header>, n: Nat, body: String,
  short: Bool) -> Reply:
  match short:
    case True{}:
      Torn{"the response body stopped before its Content-Length"}
    case False{}:
      Reply{status, headers, utf8.take(body, n)}

# a body framed by Content-Length (RFC 9110 §8.6 / RFC 9112 §6.3)
def parse.clen(status: U32, headers: List<&2, Header>, +n: Nat, +body: String)
  -> Reply:
  parse.short(status, headers, n, body, Nat.is_lt(utf8.len(body), n))

# Content-Length when present; else the rest of the connection is the body
def parse.len(status: U32, headers: List<&2, Header>, m: Maybe<&2, Nat>,
  body: String) -> Reply:
  match m:
    case None{}:
      Reply{status, headers, body}
    case Some{n}:
      parse.clen(status, headers, n, body)

# every Content-Length text equals the first
def clen.agree.step(same: Bool, rest: Unit -> Bool) -> Bool:
  match same:
    case False{}:
      False{}
    case True{}:
      rest(Unit{})

# the tail of a Content-Length list against the first value
def clen.agree.go(rest: List<&2, String>, +h: String) -> Bool:
  match rest:
    case []:
      True{}
    case x <> r:
      clen.agree.step(String.eq(x, h), _u => clen.agree.go(r, h))

# duplicate Content-Length fields must be the same digits (RFC 9112 §6.3)
def clen.agree(vs: List<&2, String>) -> Bool:
  match vs:
    case []:
      True{}
    case h <> t:
      clen.agree.go(t, h)

# whether any Content-Length field was present
def clen.any(vs: List<&2, String>) -> Bool:
  match vs:
    case []:
      False{}
    case h <> t:
      True{}

# a chunked body, or why the chunk framing was rejected
def parse.chunked(status: U32, headers: List<&2, Header>, body: String,
  bad: Maybe<&2, String>) -> Reply:
  match bad:
    case None{}:
      Reply{status, headers, dechunk(body)}
    case Some{why}:
      Torn{why}

# scan chunk sizes, then decode when they are hex and closed by 0
def parse.chunks(status: U32, headers: List<&2, Header>, +body: String) -> Reply:
  parse.chunked(status, headers, body,
    chunks.scan(String.length(body), divide(body, "\r\n")))

# Transfer-Encoding together with Content-Length is a bad message
def parse.te.clash(status: U32, headers: List<&2, Header>, body: String,
  present: Bool) -> Reply:
  match present:
    case True{}:
      Torn{"Content-Length and Transfer-Encoding conflict"}
    case False{}:
      parse.chunks(status, headers, body)

# chunked framing, or Content-Length, or the rest of the connection
def parse.te(status: U32, headers: List<&2, Header>, +lens: List<&2, String>,
  +body: String, chunked: Bool) -> Reply:
  match chunked:
    case False{}:
      parse.len(status, headers, digits.read(first(lens)), body)
    case True{}:
      parse.te.clash(status, headers, body, clen.any(lens))

# disagreeing Content-Length values are torn before framing
def parse.agree(status: U32, headers: List<&2, Header>, te: String,
  +lens: List<&2, String>, body: String, ok: Bool) -> Reply:
  match ok:
    case False{}:
      Torn{"Content-Length values disagree"}
    case True{}:
      parse.te(status, headers, lens, body,
        String.contains(String.to_lower(te), "chunked"))

# the headers that decide the framing (RFC 9112 §6.3)
def parse.frame(status: U32, headers: List<&2, Header>, te: String,
  +lens: List<&2, String>, body: String) -> Reply:
  parse.agree(status, headers, te, lens, body, clen.agree(lens))

# a head whose status line has been read (RFC 9112 §4)
def parse.status(m: Maybe<&2, U32>, +ls: List<&2, String>, body: String)
  -> Reply:
  match m:
    case None{}:
      Torn{"the response has no status line"}
    case Some{n}:
      +hs = head.list(ls)
      parse.frame(n, hs, head.go(ls, "transfer-encoding"),
        head.values(ls, "content-length"), body)

# the head's lines, with the status line read off the first
def parse.head(+ls: List<&2, String>, body: String) -> Reply:
  parse.status(U32.read(second(String.split(first(ls), ' '))), ls, body)

# a response divided into its head and everything after the blank line
# (RFC 9112 §2.1: header section ends at empty line)
def parse.cut(c: Cut) -> Reply:
  match c:
    case NoCut{}:
      Torn{"the response head has no blank line after it"}
    case Cut{before, after}:
      parse.head(String.lines(before), after)

# the status, headers, and body of a raw response
def parse(raw: String) -> Reply:
  parse.cut(divide(raw, "\r\n\r\n"))

# a parsed response on one line, for a test to read
def show(r: Reply) -> String:
  match r:
    case Torn{why}:
      "torn " ++ why
    case Reply{status, headers, body}:
      U32.show(status) ++ " " ++ body

# --- inbound request (server) and outbound response (server) ---

# a request that came apart, or the reason it would not (RFC 9112 §3)
type Request is Data:
  Bad{why: String}
  Request{method: String, target: String, headers: List<&2, Header>,
    body: String}

# reason-phrase for a few common status codes (RFC 9112 §4); others get ""
def reason(+code: U32) -> String:
  Bool.pick(String, U32.is_eq(code, 200), "OK",
    Bool.pick(String, U32.is_eq(code, 201), "Created",
      Bool.pick(String, U32.is_eq(code, 204), "No Content",
        Bool.pick(String, U32.is_eq(code, 400), "Bad Request",
          Bool.pick(String, U32.is_eq(code, 404), "Not Found",
            Bool.pick(String, U32.is_eq(code, 405), "Method Not Allowed",
              Bool.pick(String, U32.is_eq(code, 500), "Internal Server Error",
                "")))))))

# status-line + headers + body (RFC 9112 §4, §5). Connection: close ends the
# exchange after one response.
def respond(+status: U32, headers: List<&2, Header>, +body: String) -> String:
  +n = utf8.len(body)
  "HTTP/1.1 " ++ U32.show(status) ++ " " ++ reason(status) ++ "\r\n"
    ++ "Connection: close\r\n"
    ++ headers.lines(headers)
    ++ clen.line(n, Nat.is_eq(n, 0n))
    ++ "\r\n"
    ++ body

# format a structured Reply as a response message
def respond.of(r: Reply) -> String:
  match r:
    case Torn{why}:
      respond(500, [], why)
    case Reply{status, headers, body}:
      respond(status, headers, body)

# HEAD carries no message body; any other method keeps the body (RFC 9110 §9.3.2)
def reply.for.pick(reply: Reply, head: Bool) -> Reply:
  match reply head:
    case Torn{why} _:
      Torn{why}
    case Reply{status, headers, body} False{}:
      Reply{status, headers, body}
    case Reply{status, headers, body} True{}:
      Reply{status, headers, ""}

# drop a HEAD response body before it is written
def reply.for(method: String, reply: Reply) -> Reply:
  reply.for.pick(reply, String.eq(method, "HEAD"))

# the method token, or "" when the request did not parse
def method.of(req: Request) -> String:
  match req:
    case Bad{why}:
      ""
    case Request{method, target, headers, body}:
      method

# request body against Content-Length
def ask.short(method: String, target: String, headers: List<&2, Header>,
  n: Nat, body: String, short: Bool) -> Request:
  match short:
    case True{}:
      Bad{"the request body stopped before its Content-Length"}
    case False{}:
      Request{method, target, headers, utf8.take(body, n)}

# a request body framed by Content-Length (RFC 9110 §8.6 / RFC 9112 §6.3)
def ask.clen(method: String, target: String, headers: List<&2, Header>,
  +n: Nat, +body: String) -> Request:
  ask.short(method, target, headers, n, body, Nat.is_lt(utf8.len(body), n))

# Content-Length when present; else the rest of the connection is the body
def ask.len(method: String, target: String, headers: List<&2, Header>,
  m: Maybe<&2, Nat>, body: String) -> Request:
  match m:
    case None{}:
      Request{method, target, headers, body}
    case Some{n}:
      ask.clen(method, target, headers, n, body)

# a chunked request body, or why the chunk framing was rejected
def ask.chunked(method: String, target: String, headers: List<&2, Header>,
  body: String, bad: Maybe<&2, String>) -> Request:
  match bad:
    case None{}:
      Request{method, target, headers, dechunk(body)}
    case Some{why}:
      Bad{why}

# scan chunk sizes, then decode when they are hex and closed by 0
def ask.chunks(method: String, target: String, headers: List<&2, Header>,
  +body: String) -> Request:
  ask.chunked(method, target, headers, body,
    chunks.scan(String.length(body), divide(body, "\r\n")))

# Transfer-Encoding together with Content-Length is a bad request
def ask.te.clash(method: String, target: String, headers: List<&2, Header>,
  body: String, present: Bool) -> Request:
  match present:
    case True{}:
      Bad{"Content-Length and Transfer-Encoding conflict"}
    case False{}:
      ask.chunks(method, target, headers, body)

# chunked framing, or Content-Length, or the rest of the connection
def ask.te(method: String, target: String, headers: List<&2, Header>,
  +lens: List<&2, String>, +body: String, chunked: Bool) -> Request:
  match chunked:
    case False{}:
      ask.len(method, target, headers, digits.read(first(lens)), body)
    case True{}:
      ask.te.clash(method, target, headers, body, clen.any(lens))

# disagreeing Content-Length values are bad before framing
def ask.agree(method: String, target: String, headers: List<&2, Header>,
  te: String, +lens: List<&2, String>, body: String, ok: Bool) -> Request:
  match ok:
    case False{}:
      Bad{"Content-Length values disagree"}
    case True{}:
      ask.te(method, target, headers, lens, body,
        String.contains(String.to_lower(te), "chunked"))

# the headers that decide request framing (RFC 9112 §6.3)
def ask.frame(method: String, target: String, headers: List<&2, Header>,
  te: String, +lens: List<&2, String>, body: String) -> Request:
  ask.agree(method, target, headers, te, lens, body, clen.agree(lens))

# origin-form, or a bad request when the target is not an absolute-path
def ask.origin(method: String, target: String, +ls: List<&2, String>,
  body: String, ok: Bool) -> Request:
  match ok:
    case False{}:
      Bad{"the request-target is not in origin-form"}
    case True{}:
      +hs = head.list(ls)
      ask.frame(method, target, hs, head.go(ls, "transfer-encoding"),
        head.values(ls, "content-length"), body)

# request-line: method SP request-target SP HTTP-version (RFC 9112 §3)
def ask.line(method: String, +target: String, +ls: List<&2, String>,
  body: String) -> Request:
  ask.origin(method, target, ls, body, target.origin(target))

# three fields of the request-line, or torn
def ask.parts(ps: List<&2, String>, +ls: List<&2, String>, body: String)
  -> Request:
  match ps:
    case []:
      Bad{"the request has no request line"}
    case m <> rest:
      match rest:
        case []:
          Bad{"the request line has no target"}
        case t <> _ver:
          ask.line(m, t, ls, body)

# the head's lines, with the request-line read off the first
def ask.head(+ls: List<&2, String>, body: String) -> Request:
  match ls:
    case []:
      Bad{"the request has no request line"}
    case _:
      ask.parts(String.split(first(ls), ' '), ls, body)

# a request divided into its head and everything after the blank line
def ask.cut(c: Cut) -> Request:
  match c:
    case NoCut{}:
      Bad{"the request head has no blank line after it"}
    case Cut{before, after}:
      ask.head(String.lines(before), after)

# the method, target, headers, and body of a raw request
def ask(raw: String) -> Request:
  ask.cut(divide(raw, "\r\n\r\n"))

# a parsed request on one line, for a test to read
def ask.show(r: Request) -> String:
  match r:
    case Bad{why}:
      "bad " ++ why
    case Request{method, target, headers, body}:
      method ++ " " ++ target ++ " " ++ body
