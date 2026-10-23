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
      Err{Spec.wire.why(Spec.wire.code(raw), Spec.wire.text(raw))}
    case True{}:
      from.reply(Http.parse(Spec.wire.text(raw)))

# an exchange's answer as a client Response
def http.heard(+raw: String) -> Response:
  from.raw(raw, Spec.wire.ok(raw))

# an exchange as wirespec.bend wrote it: sent and read by its own method, or
# the URL's reason
def http.send(ex: Spec.Exchange) -> IO(Response):
  match ex:
    case Spec.NoUrl{why}:
      IO.pure(Response, Err{why})
    case Spec.Exchange{secure, host, port, method, req}:
      do IO<Response>:
        +raw : String <- Wire.wire.talk(secure, host, port, method, req)
        IO.pure(Response, http.heard(raw))

# a URL that came apart (or not) into an HTTP exchange
def http.loc(method: String, l: Url.Loc, headers: List<&2, Http.Header>,
  body: String) -> IO(Response):
  http.send(Spec.wire.exchange(method, l, headers, body))

# an exchange as wirespec.bend wrote it, bounded by a timeout, sent and read
# by its own method
def http.send.timed(ms: U32, ex: Spec.Exchange) -> IO(Response):
  match ex:
    case Spec.NoUrl{why}:
      IO.pure(Response, Err{why})
    case Spec.Exchange{secure, host, port, method, req}:
      do IO<Response>:
        +raw : String <- Wire.wire.talk.timed(secure, ms, host, port, method,
          req)
        IO.pure(Response, http.heard(raw))

# a URL that came apart (or not) into a GET bounded by a timeout
def http.loc.timed(ms: U32, l: Url.Loc, headers: List<&2, Http.Header>)
  -> IO(Response):
  http.send.timed(ms, Spec.wire.exchange("GET", l, headers, ""))

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
