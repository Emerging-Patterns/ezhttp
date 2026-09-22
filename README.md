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

`http.get`, `http.head`, and `http.post` return a structured client
`Response` (status, headers, body) — not a hub-style `"0\n…"` string. Pass
custom headers, including `Authorization: Bearer …` via `bearer`. TLS stays at
the wire/runtime layer (`EZ_LIBSSL` when needed).

```
import ./ezhttp/main.bend as Http
import ./ezhttp/client.bend as Client
import ./ezhttp/body.bend as Body

def main() -> IO(Client.Response):
  Http.http.get("https://example.com/")

def authed() -> IO(Client.Response):
  Http.http.get_with("https://example.com/api", [Http.bearer("token")])

def create() -> IO(Client.Response):
  Http.http.post("https://example.com/items", Http.text_body("hello"))
```

### Server

`http.serve` listens with Base TCP, accepts connections, parses one request
per connection, calls a pure handler, and writes one response
(`Connection: close`). `http.serve_once` stops after a single client. No TLS
in v0 for the server.

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

Caching, cookies, and CORS are out of v0.

## Compliance

Closed equalities in `ezhttp/LAWS.bend`, proved in `ezhttp/PROOF.bend`
(`bend ezhttp/PROOF.bend`), target:

- [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986) URI: scheme before the
  first colon, `hier-part` requiring `//`, path always absolute for the
  request-target, default ports 80 / 443 for http / https.
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) HTTP Semantics:
  case-insensitive header field names (§5.1), `Content-Length` as an exact
  octet count (§8.6), HEAD as a safe method with no request body (§9.3.2).
- [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112) HTTP/1.1 Message Syntax
  and Routing: request-line with method and request-target (§3), status-line
  (§4), header section ended by a blank line (§2.1), message framing via
  `Content-Length` / `Transfer-Encoding: chunked` / connection close (§6.3,
  §7.1, §9.6). A body shorter than its `Content-Length` is torn (client
  response) or bad (server request).

Full protocol conformance (pipelining, trailers, HTTP/2, TLS for servers,
etc.) is not claimed yet.
