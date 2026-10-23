# ezhttp: HTTP/1.1 client and server for Bend 2, with auth, cookie and CORS helpers.
#
# Shared message types, BYO JSON via encode/decode. TLS for the client stays
# at the wire/runtime layer.
import Base
import ./src/url.bend as Url
import ./src/pct.bend as Pct
import ./src/http.bend as Http
import ./src/body.bend as Body
import ./src/form.bend as Form
import ./src/client.bend as Client
import ./src/server.bend as Server
import ./src/cookie.bend as Cookie
import ./src/cache.bend as Cache
import ./src/cors.bend as Cors
import ./src/html.bend as Html
import ./src/qs.bend as Qs
import ./src/unescape.bend as Unescape
import ./src/echo.bend as Echo

# URL parse re-export
def parse_url(url: String) -> Url.Loc:  # noqa: L001 re-export of Url.parse
  Url.parse(url)

# percent-encode a path (RFC 3986 §2.1), as Python's urllib.parse.quote(text):
# unreserved characters and "/" stay, every other character becomes %XX per
# UTF-8 byte, upper-case hex (SPEC.md HTTP-URL)
def quote_path(text: String) -> String:  # noqa: L001 re-export of Pct.quote (the path form)
  Pct.quote(True{}, text)

# percent-encode a path segment, query key or value (RFC 3986 §2.1), as
# urllib.parse.quote(text, safe=""): like quote_path, but "/" becomes %2F
def quote_component(text: String) -> String:  # noqa: L001 re-export of Pct.quote (the component form)
  Pct.quote(False{}, text)

# percent-decode a string as urllib.parse.unquote: %XX escapes (either case)
# become bytes, decoded as UTF-8 with U+FFFD for bytes that are not; an escape
# that is not two hex digits is kept as written, and characters outside ASCII
# are kept (SPEC.md HTTP-QS)
def unquote(text: String) -> String:  # noqa: L001 re-export of Qs.unquote
  Qs.unquote(text)

# percent-decode as urllib.parse.unquote_plus: `+` is a space, then unquote
def unquote_plus(text: String) -> String:  # noqa: L001 re-export of Qs.unquote.plus
  Qs.unquote.plus(text)

# percent-encode as urllib.parse.quote_plus: as quote_component, but a space
# is written `+` (so `+` itself is %2B)
def quote_plus(text: String) -> String:  # noqa: L001 re-export of Qs.quote.plus
  Qs.quote.plus(text)

# a name and a value, reusable: a query field or a cookie, written (k, v)
def Kv() -> Data:  # noqa: L001 re-export of the type Qs.Kv
  Qs.Kv()

# a query string from name and value pairs, as urllib.parse.urlencode(pairs):
# `name=value` with both quote_plus'd, joined by `&`, in order
def urlencode(pairs: List<&2, Qs.Kv()>) -> String:  # noqa: L001 re-export of Qs.urlencode
  Qs.urlencode(pairs)

# a query string's name and value pairs, as
# urllib.parse.parse_qsl(text, keep_blank_values=True): split on `&`, empty
# pieces skipped, each cut at its first `=` (a piece without one is a name
# with an empty value), both unquote_plus'd. Every pair is kept, in order,
# duplicate names included; query_get reads the last one
def parse_query(text: String) -> List<&2, Qs.Kv()>:  # noqa: L001 re-export of Qs.parse
  Qs.parse(text)

# the value of the last pair with this name (names compared exactly), none
# when no pair has it: last-wins, as a dict(parse_qsl(...)) would be
def query_get(pairs: List<&2, Qs.Kv()>, name: String) -> Maybe<&2, String>:  # noqa: L001 re-export of Qs.get
  Qs.get(pairs, name)

# response parse re-export
def parse_response(raw: String) -> Http.Reply:  # noqa: L001 re-export of Http.parse
  Http.parse(raw)

# a response as the client reads it for a request with this method: interim
# 1xx heads skipped, and no body for HEAD or a 1xx, 204 or 304 status,
# whatever Content-Length says (SPEC.md HTTP-CLI-9)
def parse_response_to(method: String, raw: String) -> Http.Reply:  # noqa: L001 re-export of Http.parse.to
  Http.parse.to(method, raw)

# the reason phrase of a response's status line (RFC 9112 §4), read from the
# head parse_response_to stops at; empty when there is none (SPEC.md
# HTTP-CLI-11)
def reason_phrase(raw: String) -> String:  # noqa: L001 re-export of Http.phrase.to
  Http.phrase.to(raw)

# request parse re-export (server inbound)
def parse_request(raw: String) -> Http.Request:  # noqa: L001 re-export of Http.ask
  Http.ask(raw)

# format a response message (server outbound)
def format_response(status: U32, headers: List<&2, Http.Header>, body: String)  # noqa: L001 re-export of Http.respond
  -> String:
  Http.respond(status, headers, body)

# empty request body
def empty_body() -> Body.Body:  # noqa: L001 re-export of Body.body.empty
  Body.body.empty()

# UTF-8 text request body
def text_body(text: String) -> Body.Body:  # noqa: L001 re-export of Body.body.text
  Body.body.text(text)

# octet-list request body
def octets_body(bs: List<&2, U32>) -> Body.Body:  # noqa: L001 re-export of Body.body.octets
  Body.body.octets(bs)

# a multipart/form-data text field (RFC 7578)
def form_field(name: String, value: String) -> Form.Part:  # noqa: L001 re-export of Form.form.field
  Form.form.field(name, value)

# a multipart/form-data file part: field name, filename, content type and the
# file's bytes (each 0..255, as File.read_bytes gives them)
def form_file(name: String, filename: String, ctype: String,  # noqa: L001 re-export of Form.form.file
  bytes: List<&2, U32>) -> Form.Part:
  Form.form.file(name, filename, ctype, bytes)

# a multipart/form-data body (RFC 7578) with this boundary: the Content-Type
# field value to send and an octet body, or why the boundary cannot be used
# (SPEC.md HTTP-FORM)
def form_body(boundary: String, parts: List<&2, Form.Part>) -> Form.Form:  # noqa: L001 re-export of Form.form.body
  Form.form.body(boundary, parts)

# BYO JSON (or any codec): encode a value with the caller's to_text
def encode(~A: Data, ~to_text: A -> String, value: A) -> Body.Body:  # noqa: L001 re-export of Body.body.encode
  Body.body.encode(A, to_text, value)

# BYO JSON (or any codec): decode body text with the caller's from_text
def decode(  # noqa: L001 re-export of Body.body.decode
  ~A: Data,
  ~from_text: String -> Maybe<&2, A>,
  text: String
) -> Maybe<&2, A>:
  Body.body.decode(A, from_text, text)

# Bearer token header helper
def bearer(token: String) -> Http.Header:  # noqa: L001 re-export of client.bearer = Auth.auth.bearer
  Client.client.bearer(token)

# Basic credentials header (RFC 7617)
def basic(user: String, password: String) -> Http.Header:  # noqa: L001 re-export of client.basic = Auth.auth.basic
  Client.client.basic(user, password)

# Set-Cookie header from a parsed cookie (RFC 6265)
def set_cookie(cookie: Cookie.Cookie) -> Http.Header:  # noqa: L001 re-export of Cookie.cookie.set
  Cookie.cookie.set(cookie)

# parse one Set-Cookie field value
def parse_cookie(line: String) -> Maybe<&2, Cookie.Cookie>:  # noqa: L001 re-export of Cookie.cookie.parse
  Cookie.cookie.parse(line)

# Cookie request header for a list of cookies
def cookie_header(cs: List<&2, Cookie.Cookie>) -> Http.Header:  # noqa: L001 re-export of Cookie.cookie.request
  Cookie.cookie.request(cs)

# parse a Cache-Control field value (RFC 9111)
def cache_control(value: String) -> Cache.Cc:  # noqa: L001 re-export of Cache.cache.parse
  Cache.cache.parse(value)

# freshness of a Cache-Control value at an age in seconds
def fresh(value: String, age: Nat) -> Bool:  # noqa: L001 Cache.cache.fresh of Cache.cache.parse
  Cache.cache.fresh(Cache.cache.parse(value), age)

# CORS preflight or simple headers on a handler reply
def cors_reply(  # noqa: L001 re-export of Cors.cors.on
  cfg: Cors.Cfg,
  req: Http.Request,
  reply: Http.Reply
) -> Http.Reply:
  Cors.cors.on(cfg, req, reply)

# escape text for HTML as markupsafe and Jinja's autoescape do: & < > " ' as
# &amp; &lt; &gt; &#34; &#39;, every other character as itself
def html_escape(text: String) -> String:  # noqa: L001 re-export of Html.escape
  Html.escape(text)

# HTML character references back to characters, as Python's html.unescape:
# decimal and hex numeric references (with the HTML Standard's replacements)
# and the HTML Standard's 2231 named references, the legacy ones also without
# `;`; anything that is not a reference is kept as written (SPEC.md HTTP-REF)
def html_unescape(text: String) -> String:  # noqa: L001 re-export of Unescape.unescape
  Unescape.unescape(text)

# the Cookie header value to send back after these Set-Cookie field values
# (RFC 6265 §5.2, §5.4): each one's name=value, attributes ignored; a later
# cookie with the same name replaces the earlier one's value in its place;
# `name=value` pairs joined by `; ` (SPEC.md HTTP-CK)
def cookie_from_set_cookies(values: List<&2, String>) -> String:  # noqa: L001 re-export of Echo.echo
  Echo.echo(values)

# the same, from a response's header fields (its Set-Cookie fields, in order)
def cookie_from_headers(headers: List<&2, Http.Header>) -> String:  # noqa: L001 Echo.echo of Echo.values
  Echo.echo(Echo.values(headers))

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
  Client.client.request.opts(method, url, headers, body, timeout_ms, follow)

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
