# ezhttp

HTTP client and server for [Bend 2](https://github.com/bendlang/bend).

## Install

Use with [Bend](https://github.com/bendlang/bend) or install easily with [ez](https://github.com/Emerging-Patterns/ez):

```
ez init
ez add Emerging-Patterns/ezhttp
```

## Usage

Shared types cover both sides: `Header`, structured `Request` / `Reply`
(status or method, headers, body). Bodies are empty, UTF-8 text, or an octet
list. JSON is bring-your-own via `encode` / `decode` — core does not depend on
ezjson.

### Client

`http.get`, `http.head`, `http.post`, `http.put`, `http.delete`, and
`http.options` return a structured client `Response` (status, headers, body).
Pass custom headers: `bearer` writes `Authorization: Bearer …`, and `basic`
writes `Authorization: Basic …` (RFC 7617, RFC 4648). TLS stays at the
wire/runtime layer (`EZ_LIBSSL` when needed). `https` selects that TLS path
and port 443.

```
import ./ezhttp/main.bend as Http
import ./ezhttp/client.bend as Client
import ./ezhttp/body.bend as Body

def main() -> IO(Client.Response):
  Http.http.get("https://example.com/")

def authed() -> IO(Client.Response):
  Http.http.get_with("https://example.com/api", [Http.bearer("token")])

def create() -> IO(Client.Response):
  Http.http.put("https://example.com/items", Http.text_body("hello"))
```

### Server

`http.serve` listens with Base TCP, accepts connections, parses one request
per connection, calls a pure handler, and writes one response
(`Connection: close`). `http.serve_once` stops after a single client. No TLS
in v0 for the server. A HEAD response is written with an empty body.

```
import ./ezhttp/main.bend as Http
import ./ezhttp/http.bend as Msg

def handle(req: Msg.Request) -> Msg.Reply:
  match req:
    case Msg.Bad{why}:
      Msg.Reply{400, [], why}
    case Msg.Request{method, target, headers, body}:
      Msg.Reply{200, [], "ok"}

def main() -> IO(Unit):
  Http.http.serve(handle, 8080, 1024)
```

Cookies, `Cache-Control`, and CORS are pure helpers on the same messages.

```
import ./ezhttp/main.bend as Http
import ./ezhttp/http.bend as Msg
import ./ezhttp/cookie.bend as Cookie
import ./ezhttp/cors.bend as Cors

def authed() -> Msg.Header:
  Http.basic("user", "pass")

def jar() -> Msg.Header:
  Http.cookie_header([Cookie.cookie.new("a", "b")])

def cacheable(value: String) -> Bool:
  Http.fresh(value, 0n)

def cross(cfg: Cors.Cfg, req: Msg.Request, reply: Msg.Reply) -> Msg.Reply:
  Http.cors_reply(cfg, req, reply)
```

`parse_cookie` reads a `Set-Cookie` field value. `set_cookie` writes one.
`cache_control` reads `no-store`, `no-cache`, `max-age`, `public`, and
`private`. `cors_reply` answers a simple request or an OPTIONS preflight from
`allow_origins`, methods, headers, credentials, and `max_age`. Credentials
never pair with `Access-Control-Allow-Origin: *`.

## Compliance

Closed equalities in `ezhttp/LAWS.bend`, proved in `ezhttp/PROOF.bend`
(`bend ezhttp/PROOF.bend`), target:

- [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986) URI: scheme before the
  first colon and lowercased (§3.1), `hier-part` requiring `//` (§3),
  userinfo stripped from the authority (§3.2.1), IPv4 host and explicit port
  (§3.2.2, §3.2.3), path always absolute for the request-target (§3.3), query
  kept and fragment dropped (§3.4, §3.5), default ports 80 / 443.
- [RFC 2818](https://www.rfc-editor.org/rfc/rfc2818) HTTP over TLS: scheme
  `https` selects the TLS wire path and port 443. The TLS handshake itself
  stays in the runtime.
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) HTTP Semantics:
  case-insensitive field names (§5.1), optional whitespace trimmed and
  obs-fold rejected (§5.5), `Host` on every HTTP/1.1 client request (§7.2),
  `Content-Length` as an exact octet count (§8.6), safe methods GET / HEAD /
  OPTIONS (§9.2.1), idempotent methods adding PUT / DELETE (§9.2.2), method
  tokens case-sensitive (§9.3), HEAD response body omitted (§9.3.2), PUT /
  DELETE / OPTIONS request lines (§9.3.4, §9.3.5, §9.3.7), reason-phrases for
  200, 400, 404, and 500 (§15).
- [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112) HTTP/1.1 Message Syntax
  and Routing: header section ended by a blank line (§2.1), origin-form
  request-target (§3.2.1), status-line `HTTP/1.1` (§4), `Content-Length`
  values that disagree and `Content-Length` together with
  `Transfer-Encoding` are rejected (§6.3), chunked bodies including a second
  non-empty chunk and a non-hex chunk size (§7.1), `Connection: close`
  (§9.6). A body shorter than its `Content-Length` is torn (client response)
  or bad (server request).
- [RFC 4648](https://www.rfc-editor.org/rfc/rfc4648) Base64 (§4, §10) and
  [RFC 7617](https://www.rfc-editor.org/rfc/rfc7617) Basic authentication
  (§2): `Authorization: Basic` is Base64 of `user:password`.
- [RFC 6750](https://www.rfc-editor.org/rfc/rfc6750) Bearer (§2.1):
  `Authorization: Bearer` plus a token with no whitespace.
- [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265) cookies: `Set-Cookie`
  name=value and attributes Expires, Max-Age, Domain, Path, Secure, HttpOnly,
  SameSite (§4.1.1), domain-match and path-match (§5.1.3, §5.1.4), the
  `Cookie` request header joined by `; ` (§5.4). An empty cookie-name is
  rejected. Expires is stored and not compared to a clock. SameSite is
  stored; there is no browsing context to suppress a cross-site send.
- [RFC 9111](https://www.rfc-editor.org/rfc/rfc9111) HTTP Caching: `max-age`
  freshness, including `max-age=0` stale (§4.2.1), `Cache-Control` directives
  `no-store`, `no-cache`, `max-age`, `public`, `private` with case-insensitive
  names (§5.2), and `Expires` recorded beside them (§5.3). This is not a
  shared cache.
- [Fetch CORS protocol](https://fetch.spec.whatwg.org/#cors-protocol):
  `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`,
  `Access-Control-Allow-Headers`, `Access-Control-Allow-Credentials`,
  `Access-Control-Max-Age`, `Access-Control-Expose-Headers`, and the request
  headers `Origin`, `Access-Control-Request-Method`,
  `Access-Control-Request-Headers`. A small allow-list answers a simple
  request and an OPTIONS preflight. Credentials never emit `*`.

Not claimed: HTTP/2 (RFC 9113), HTTP/3 (RFC 9114), a TLS handshake in the
server, multipart bodies, pipelining, trailers, 1xx / `Expect`, a shared
cache or IMF-fixdate arithmetic, a full cookie jar (public suffix, eviction,
the Expires clock, SameSite cross-site suppression), `allow_origin_regex`,
IPv6 literals, asterisk-form and absolute-form request-targets, and unfolding
obs-fold (it is rejected). Userinfo is stripped, not turned into
`Authorization`.
