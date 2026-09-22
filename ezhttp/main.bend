# ezhttp: HTTP client and server for Bend 2. Shared message types, BYO JSON
# via encode/decode. TLS for the client stays at the wire/runtime layer.
import Base
import ./url.bend as Url
import ./http.bend as Http
import ./body.bend as Body
import ./client.bend as Client
import ./server.bend as Server
import ./cookie.bend as Cookie
import ./cache.bend as Cache
import ./cors.bend as Cors

# URL parse re-export
def parse_url(url: String) -> Url.Loc:
  Url.parse(url)

# response parse re-export
def parse_response(raw: String) -> Http.Reply:
  Http.parse(raw)

# request parse re-export (server inbound)
def parse_request(raw: String) -> Http.Request:
  Http.ask(raw)

# format a response message (server outbound)
def format_response(status: U32, headers: List<&2, Http.Header>, body: String)
  -> String:
  Http.respond(status, headers, body)

# empty request body
def empty_body() -> Body.Body:
  Body.body.empty()

# UTF-8 text request body
def text_body(s: String) -> Body.Body:
  Body.body.text(s)

# octet-list request body
def octets_body(bs: List<&2, U32>) -> Body.Body:
  Body.body.octets(bs)

# BYO JSON (or any codec): encode a value with the caller's to_text
def encode(~A: Data, ~to_text: A -> String, value: A) -> Body.Body:
  Body.body.encode(A, to_text, value)

# BYO JSON (or any codec): decode body text with the caller's from_text
def decode(
  ~A: Data,
  ~from_text: String -> Maybe<&2, A>,
  s: String
) -> Maybe<&2, A>:
  Body.body.decode(A, from_text, s)

# Bearer token header helper
def bearer(token: String) -> Http.Header:
  Client.client.bearer(token)

# Basic credentials header (RFC 7617)
def basic(user: String, password: String) -> Http.Header:
  Client.client.basic(user, password)

# Set-Cookie header from a parsed cookie (RFC 6265)
def set_cookie(c: Cookie.Cookie) -> Http.Header:
  Cookie.cookie.set(c)

# parse one Set-Cookie field value
def parse_cookie(line: String) -> Maybe<&2, Cookie.Cookie>:
  Cookie.cookie.parse(line)

# Cookie request header for a list of cookies
def cookie_header(cs: List<&2, Cookie.Cookie>) -> Http.Header:
  Cookie.cookie.request(cs)

# parse a Cache-Control field value (RFC 9111)
def cache_control(value: String) -> Cache.Cc:
  Cache.cache.parse(value)

# freshness of a Cache-Control value at an age in seconds
def fresh(value: String, age: Nat) -> Bool:
  Cache.cache.fresh(Cache.cache.parse(value), age)

# CORS preflight or simple headers on a handler reply
def cors_reply(cfg: Cors.Cfg, req: Http.Request, reply: Http.Reply) -> Http.Reply:
  Cors.cors.on(cfg, req, reply)

# GET with no extra headers
def http.get(url: String) -> IO(Client.Response):
  Client.client.get(url, [])

# GET with headers
def http.get_with(url: String, headers: List<&2, Http.Header>)
  -> IO(Client.Response):
  Client.client.get(url, headers)

# HEAD with no extra headers
def http.head(url: String) -> IO(Client.Response):
  Client.client.head(url, [])

# HEAD with headers
def http.head_with(url: String, headers: List<&2, Http.Header>)
  -> IO(Client.Response):
  Client.client.head(url, headers)

# POST with a body and no extra headers
def http.post(url: String, body: Body.Body) -> IO(Client.Response):
  Client.client.post(url, [], body)

# POST with headers and a body
def http.post_with(
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body
) -> IO(Client.Response):
  Client.client.post(url, headers, body)

# PUT with a body and no extra headers
def http.put(url: String, body: Body.Body) -> IO(Client.Response):
  Client.client.put(url, [], body)

# PUT with headers and a body
def http.put_with(url: String, headers: List<&2, Http.Header>, body: Body.Body)
  -> IO(Client.Response):
  Client.client.put(url, headers, body)

# DELETE with a body and no extra headers
def http.delete(url: String, body: Body.Body) -> IO(Client.Response):
  Client.client.delete(url, [], body)

# DELETE with headers and a body
def http.delete_with(
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body
) -> IO(Client.Response):
  Client.client.delete(url, headers, body)

# OPTIONS with no extra headers
def http.options(url: String) -> IO(Client.Response):
  Client.client.options(url, [])

# OPTIONS with headers
def http.options_with(url: String, headers: List<&2, Http.Header>)
  -> IO(Client.Response):
  Client.client.options(url, headers)

# listen and serve up to `limit` connections
def http.serve(
  ~handle: Http.Request -> Http.Reply,
  port: U32,
  limit: U32
) -> IO(Unit):
  Server.server.serve(handle, port, limit)

# serve one connection then stop
def http.serve_once(~handle: Http.Request -> Http.Reply, port: U32) -> IO(Unit):
  Server.server.once(handle, port)
