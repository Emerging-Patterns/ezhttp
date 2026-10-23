# ezhttp: HTTP/1.1 client and server for Bend 2, with auth, cookie and CORS helpers.
#
# Shared message types, BYO JSON via encode/decode. TLS for the client stays
# at the wire/runtime layer.
import Base
import ./src/url.bend as Url
import ./src/pct.bend as Pct
import ./src/http.bend as Http
import ./src/body.bend as Body
import ./src/client.bend as Client
import ./src/server.bend as Server
import ./src/cookie.bend as Cookie
import ./src/cache.bend as Cache
import ./src/cors.bend as Cors
import ./src/html.bend as Html

# URL parse re-export
def parse_url(url: String) -> Url.Loc:
  Url.parse(url)

# percent-encode a path (RFC 3986 §2.1), as Python's urllib.parse.quote(text):
# unreserved characters and "/" stay, every other character becomes %XX per
# UTF-8 byte, upper-case hex (SPEC.md HTTP-URL)
def quote_path(text: String) -> String:
  Pct.quote(True{}, text)

# percent-encode a path segment, query key or value (RFC 3986 §2.1), as
# urllib.parse.quote(text, safe=""): like quote_path, but "/" becomes %2F
def quote_component(text: String) -> String:
  Pct.quote(False{}, text)

# response parse re-export
def parse_response(raw: String) -> Http.Reply:
  Http.parse(raw)

# a response as the client reads it for a request with this method: interim
# 1xx heads skipped, and no body for HEAD or a 1xx, 204 or 304 status,
# whatever Content-Length says (SPEC.md HTTP-CLI-9)
def parse_response_to(method: String, raw: String) -> Http.Reply:
  Http.parse.to(method, raw)

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
def text_body(text: String) -> Body.Body:
  Body.body.text(text)

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
  text: String
) -> Maybe<&2, A>:
  Body.body.decode(A, from_text, text)

# Bearer token header helper
def bearer(token: String) -> Http.Header:
  Client.client.bearer(token)

# Basic credentials header (RFC 7617)
def basic(user: String, password: String) -> Http.Header:
  Client.client.basic(user, password)

# Set-Cookie header from a parsed cookie (RFC 6265)
def set_cookie(cookie: Cookie.Cookie) -> Http.Header:
  Cookie.cookie.set(cookie)

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

# escape text for HTML as markupsafe and Jinja's autoescape do: & < > " ' as
# &amp; &lt; &gt; &#34; &#39;, every other character as itself
def html_escape(text: String) -> String:
  Html.escape(text)

# GET with no extra headers
def http.get(url: String) -> IO(Client.Response):
  Client.client.get(url, [])

# GET with headers
def http.get_with(url: String, headers: List<&2, Http.Header>)
  -> IO(Client.Response):
  Client.client.get(url, headers)

# GET with headers and a timeout in milliseconds that bounds connecting,
# sending and receiving; with `follow`, redirects are followed (GET only, at
# most 10 hops, see src/redirect.bend)
def http.get_opts(
  url: String,
  headers: List<&2, Http.Header>,
  timeout_ms: U32,
  follow: Bool
) -> IO(Client.Response):
  Client.client.get.opts(url, headers, timeout_ms, follow)

# a request with any method, headers, a body and a timeout in milliseconds
# that bounds connecting, sending and receiving; with `follow`, a GET follows
# redirects (at most 10 hops, see src/redirect.bend) and every other method
# answers a redirect as its response
def http.request_opts(
  method: String,
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body,
  timeout_ms: U32,
  follow: Bool
) -> IO(Client.Response):
  Client.client.request.opts(method, url, headers, Body.body.payload(body),
    timeout_ms, follow)

# POST with headers, a body and a timeout in milliseconds; redirects are not
# followed
def http.post_opts(
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body,
  timeout_ms: U32
) -> IO(Client.Response):
  http.request_opts("POST", url, headers, body, timeout_ms, False{})

# PUT with headers, a body and a timeout in milliseconds; redirects are not
# followed
def http.put_opts(
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body,
  timeout_ms: U32
) -> IO(Client.Response):
  http.request_opts("PUT", url, headers, body, timeout_ms, False{})

# DELETE with headers, a body and a timeout in milliseconds; redirects are
# not followed
def http.delete_opts(
  url: String,
  headers: List<&2, Http.Header>,
  body: Body.Body,
  timeout_ms: U32
) -> IO(Client.Response):
  http.request_opts("DELETE", url, headers, body, timeout_ms, False{})

# whether a response is an exchange that ran out of time
def http.timed_out(r: Client.Response) -> Bool:
  Client.client.timed_out(r)

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

# listen on host:port and serve up to `limit` connections
def http.serve(
  ~handle: Http.Request -> Http.Reply,
  host: String,
  port: U32,
  limit: U32
) -> IO(Unit):
  Server.server.serve(handle, host, port, limit)

# listen on host:port and serve up to `limit` connections with a handler that
# does IO; a failed connection is logged and the next one is served
def http.serve_io(
  ~handle: Http.Request -> IO(Http.Reply),
  host: String,
  port: U32,
  limit: U32
) -> IO(Unit):
  Server.server.serve_io(handle, host, port, limit)

# listen on host:port and serve with an IO handler until the process stops
@unsafe def http.serve_forever(
  ~handle: Http.Request -> IO(Http.Reply),
  host: String,
  port: U32
) -> IO(Unit):
  Server.server.serve_forever(handle, host, port)

# listen on host:port, serve one connection, then stop
def http.serve_once(
  ~handle: Http.Request -> Http.Reply,
  host: String,
  port: U32
) -> IO(Unit):
  Server.server.once(handle, host, port)
