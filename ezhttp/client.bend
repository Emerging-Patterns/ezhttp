# ezhttp/client: fetch a URL. URL and HTTP parsing joined to the wire effect.
# Answers a structured Response (status + headers + body), not a hub-style
# "0\n…" string contract.
import Base
import ./url.bend as Url
import ./http.bend as Http
import ./body.bend as Body
import ./wire.bend as Wire
import ./b64.bend as B64

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

# a finished exchange
def from.raw(raw: String, ok: Bool) -> Response:
  match ok:
    case False{}:
      Err{wire.text(raw)}
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

# Authorization: Bearer …
def client.bearer(token: String) -> Http.Header:
  Http.H{"Authorization", "Bearer " ++ token}

# Authorization: Basic … (RFC 7617, credentials are RFC 4648 Base64)
def client.basic(user: String, password: String) -> Http.Header:
  Http.H{"Authorization", "Basic " ++ B64.b64.encode(user ++ ":" ++ password)}
