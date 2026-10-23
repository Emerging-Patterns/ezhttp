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

# structured client result: transport/parse error, or an HTTP response with
# its status line's reason phrase (SPEC.md HTTP-CLI-11)
type Response is Data:
  Err{why: String}
  Response{status: U32, headers: List<&2, Http.Header>, body: String,
    reason: String}

# a torn or successful HTTP parse as a client Response, with the reason
# phrase read from the same text
def from.reply(r: Http.Reply, reason: String) -> Response:
  match r:
    case Http.Torn{why}:
      Err{why}
    case Http.Reply{status, headers, body}:
      Response{status, headers, body, reason}

# an exchange's answer as a client Response, read by the request's method
# (wirespec.bend wire.heard: interim 1xx heads skipped, no body for HEAD,
# 1xx, 204 or 304; a failed exchange keeps its reason)
def http.heard(+method: String, +raw: String) -> Response:
  from.reply(Spec.wire.heard(method, raw), Spec.wire.phrase(raw))

# an exchange as wirespec.bend wrote it, with the body's tail of octets: sent
# and read by its own method, or the URL's reason
def http.send(ex: Spec.Exchange, tail: List<&2, U32>) -> IO(Response):
  match ex:
    case Spec.NoUrl{why}:
      IO.pure(Response, Err{why})
    case Spec.Exchange{secure, host, port, +method, req}:
      do IO<Response>:
        +raw : String <- Wire.wire.talk(secure, host, port, method, req, tail)
        IO.pure(Response, http.heard(method, raw))

# a URL that came apart (or not) into an HTTP exchange with this body
def http.loc(method: String, l: Url.Loc, headers: List<&2, Http.Header>,
  +body: Body.Body) -> IO(Response):
  http.send(Spec.wire.exchange.body(method, l, headers, body),
    Spec.wire.tail(body))

# an exchange as wirespec.bend wrote it, bounded by a timeout, sent and read
# by its own method
def http.send.timed(ms: U32, ex: Spec.Exchange, tail: List<&2, U32>)
  -> IO(Response):
  match ex:
    case Spec.NoUrl{why}:
      IO.pure(Response, Err{why})
    case Spec.Exchange{secure, host, port, +method, req}:
      do IO<Response>:
        +raw : String <- Wire.wire.talk.timed(secure, ms, host, port, method,
          req, tail)
        IO.pure(Response, http.heard(method, raw))

# a request with this method, headers and body, bounded by a timeout in
# milliseconds
def client.timed(method: String, url: String, headers: List<&2, Http.Header>,
  +body: Body.Body, ms: U32) -> IO(Response):
  http.send.timed(ms, Spec.wire.exchange.body(method, Url.parse(url), headers,
    body), Spec.wire.tail(body))

# GET bounded by a timeout in milliseconds
def client.get.timed(url: String, headers: List<&2, Http.Header>, ms: U32)
  -> IO(Response):
  client.timed("GET", url, headers, Body.Empty{}, ms)

# the next hop after a response (redirect.bend); a failed exchange stops
def client.hop(left: Nat, url: String, r: Response) -> Redirect.Hop:
  match r:
    case Err{why}:
      Redirect.Stop{}
    case Response{status, headers, body, reason}:
      Redirect.redirect.plan(left, url, status, headers)

# a response, or the GET its hop asks for
def client.after(hop: Redirect.Hop, r: Response, go: String -> IO(Response))
  -> IO(Response):
  match hop:
    case Redirect.Stop{}:
      IO.pure(Response, r)
    case Redirect.Go{next}:
      go(next)

# GET, following redirects while `left` hops remain; `body` goes with this
# hop only. The answer is the last response, which is a redirect only when
# the hops ran out or its Location is not one redirect.bend follows
def client.follow(+left: Nat, +url: String, +headers: List<&2, Http.Header>,
  body: Body.Body, +ms: U32) -> IO(Response):
  match left:
    case 0n:
      client.timed("GET", url, headers, body, ms)
    case 1n+p:
      do IO<Response>:
        +r : Response <- client.timed("GET", url, headers, body, ms)
        client.after(client.hop(left, url, r), r,
          next => client.follow(p, next, headers, Body.Empty{}, ms))

# a request once it is known whether it follows redirects
def client.request.go(go: Bool, method: String, url: String,
  headers: List<&2, Http.Header>, body: Body.Body, ms: U32) -> IO(Response):
  match go:
    case True{}:
      client.follow(Redirect.redirect.max(), url, headers, body, ms)
    case False{}:
      client.timed(method, url, headers, body, ms)

# a request with a method, headers, body and timeout; it follows redirects
# when `follow` is set and the method is GET (redirect.bend
# redirect.follows), and answers its first response otherwise
def client.request.opts(+method: String, url: String,
  headers: List<&2, Http.Header>, body: Body.Body, ms: U32, follow: Bool)
  -> IO(Response):
  client.request.go(Redirect.redirect.follows(method, follow), method, url,
    headers, body, ms)

# GET with headers and a timeout, following redirects when `follow` is set
def client.get.opts(url: String, headers: List<&2, Http.Header>, ms: U32,
  follow: Bool) -> IO(Response):
  client.request.opts("GET", url, headers, Body.Empty{}, ms, follow)

# whether a response is the failure of an exchange that ran out of time
def client.timed_out(r: Response) -> Bool:
  match r:
    case Err{why}:
      Spec.wire.timed_out(why)
    case Response{status, headers, body, reason}:
      False{}

# GET
def client.get(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("GET", Url.parse(url), headers, Body.Empty{})

# HEAD (RFC 9110 §9.3.2)
def client.head(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("HEAD", Url.parse(url), headers, Body.Empty{})

# POST
def client.post(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("POST", Url.parse(url), headers, body)

# PUT
def client.put(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("PUT", Url.parse(url), headers, body)

# DELETE
def client.delete(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Response):
  http.loc("DELETE", Url.parse(url), headers, body)

# OPTIONS
def client.options(url: String, headers: List<&2, Http.Header>) -> IO(Response):
  http.loc("OPTIONS", Url.parse(url), headers, Body.Empty{})

# Authorization: Bearer … (auth.bend)
def client.bearer(token: String) -> Http.Header:
  Auth.auth.bearer(token)

# Authorization: Basic … (auth.bend; RFC 7617, RFC 4648 Base64)
def client.basic(user: String, password: String) -> Http.Header:
  Auth.auth.basic(user, password)
