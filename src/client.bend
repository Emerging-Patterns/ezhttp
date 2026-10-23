# ezhttp/src/client: fetch a URL. URL and HTTP parsing joined to the wire effect.
# Answers a structured Response (status + headers + body), not a hub-style
# "0\n…" string contract.
import Base
import ./url.bend as Url
import ./http.bend as Http
import ./body.bend as Body
import ./wire.bend as Wire
import ./wirespec.bend as Spec
import ./redirect.bend as Redirect
import ./auth.bend as Auth

# structured client result: transport/parse error, or an HTTP response
type Response is Data:
  Err{why: String}
  Response{status: U32, headers: List<&2, Http.Header>, body: String}

# transport status line: first line is a code, rest is the payload
def wire.code(raw: String) -> Maybe<&2, U32>:
  U32.read(Http.first(String.split(raw, '\n')))

# text after the first newline
def wire.text.of(c: Http.Cut) -> String:
  match c:
    case Http.NoCut{}:
      ""
    case Http.Cut{_before, after}:
      after

def wire.text(raw: String) -> String:
  wire.text.of(Http.divide(raw, "\n"))

# whether the wire status is success (0)
def wire.ok.of(m: Maybe<&2, U32>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{n}:
      U32.is_eq(n, 0)

def wire.ok(raw: String) -> Bool:
  wire.ok.of(wire.code(raw))

# a torn or successful HTTP parse as a client Response
def from.reply(r: Http.Reply) -> Response:
  match r:
    case Http.Torn{why}:
      Err{why}
    case Http.Reply{status, headers, body}:
      Response{status, headers, body}

# a finished exchange; a failed one keeps its reason, marked when it was a
# timeout (wirespec.bend wire.why)
def from.raw(+raw: String, ok: Bool) -> Response:
  match ok:
    case False{}:
      Err{Spec.wire.why(wire.code(raw), wire.text(raw))}
    case True{}:
      from.reply(Http.parse(wire.text(raw)))

# HTTP(S) exchange with a pre-built request
def http.talk(secure: Bool, host: String, port: U32, req: String)
  -> IO(Response):
  do IO<Response>:
    +raw : String <- Wire.wire.talk(secure, host, port, req)
    IO.pure(Response, from.raw(raw, wire.ok(raw)))

# a URL that came apart into an HTTP exchange
def http.loc(method: String, l: Url.Loc, headers: List<&2, Http.Header>,
  body: String) -> IO(Response):
  match l:
    case Url.Bad{why}:
      IO.pure(Response, Err{why})
    case Url.Loc{+scheme, +host, port, path}:
      http.talk(String.eq(scheme, "https"), host, port,
        Http.request(method, host, path, headers, body))

# HTTP(S) exchange with a pre-built request and a timeout in milliseconds
def http.talk.timed(secure: Bool, ms: U32, host: String, port: U32,
  req: String) -> IO(Response):
  do IO<Response>:
    +raw : String <- Wire.wire.talk.timed(secure, ms, host, port, req)
    IO.pure(Response, from.raw(raw, wire.ok(raw)))

# a URL that came apart into a GET bounded by a timeout
def http.loc.timed(ms: U32, l: Url.Loc, headers: List<&2, Http.Header>)
  -> IO(Response):
  match l:
    case Url.Bad{why}:
      IO.pure(Response, Err{why})
    case Url.Loc{+scheme, +host, port, path}:
      http.talk.timed(String.eq(scheme, "https"), ms, host, port,
        Http.request("GET", host, path, headers, ""))

# GET bounded by a timeout in milliseconds
def client.get.timed(url: String, headers: List<&2, Http.Header>, ms: U32)
  -> IO(Response):
  http.loc.timed(ms, Url.parse(url), headers)

# the next hop after a response (redirect.bend); a failed exchange stops
def client.hop(left: Nat, url: String, r: Response) -> Redirect.Hop:
  match r:
    case Err{why}:
      Redirect.Stop{}
    case Response{status, headers, body}:
      Redirect.redirect.plan(left, url, status, headers)

# a response, or the GET its hop asks for
def client.after(hop: Redirect.Hop, r: Response, go: String -> IO(Response))
  -> IO(Response):
  match hop:
    case Redirect.Stop{}:
      IO.pure(Response, r)
    case Redirect.Go{next}:
      go(next)

# GET, following redirects while `left` hops remain; the answer is the last
# response, which is a redirect only when the hops ran out or its Location
# is not one redirect.bend follows
def client.follow(+left: Nat, +url: String, +headers: List<&2, Http.Header>,
  +ms: U32) -> IO(Response):
  match left:
    case 0n:
      client.get.timed(url, headers, ms)
    case 1n+p:
      do IO<Response>:
        +r : Response <- client.get.timed(url, headers, ms)
        client.after(client.hop(left, url, r), r,
          next => client.follow(p, next, headers, ms))

# GET with headers and a timeout, following redirects when `follow` is set
def client.get.opts(url: String, headers: List<&2, Http.Header>, ms: U32,
  follow: Bool) -> IO(Response):
  match follow:
    case True{}:
      client.follow(Redirect.redirect.max(), url, headers, ms)
    case False{}:
      client.get.timed(url, headers, ms)

# whether a response is the failure of an exchange that ran out of time
def client.timed_out(r: Response) -> Bool:
  match r:
    case Err{why}:
      Spec.wire.timed_out(why)
    case Response{status, headers, body}:
      False{}

# GET
def client.get(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("GET", Url.parse(url), headers, "")

# HEAD (RFC 9110 §9.3.2)
def client.head(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("HEAD", Url.parse(url), headers, "")

# POST
def client.post(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("POST", Url.parse(url), headers, Body.body.payload(body))

# PUT
def client.put(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("PUT", Url.parse(url), headers, Body.body.payload(body))

# DELETE
def client.delete(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("DELETE", Url.parse(url), headers, Body.body.payload(body))

# OPTIONS
def client.options(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("OPTIONS", Url.parse(url), headers, "")

# Authorization: Bearer … (auth.bend)
def client.bearer(token: String) -> Http.Header:
  Auth.auth.bearer(token)

# Authorization: Basic … (auth.bend; RFC 7617, RFC 4648 Base64)
def client.basic(user: String, password: String) -> Http.Header:
  Auth.auth.basic(user, password)
