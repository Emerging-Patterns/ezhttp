# ezhttp

HTTP client and server for [Bend 2](https://github.com/bendlang/bend).

## Install

It needs bend 2.0.38 or later (a failed `TCP.send` hands back the unsent
bytes as a list).
ezhttp is built and checked on bend 2.0.38.

With [Bend](https://github.com/bendlang/bend) alone there is no install
step: import ezhttp by its hub name and `bend` fetches it from
[the hub](https://hub.bend-lang.com) into `~/.bend/lib` on the first run.
`ezhttp@0.22.0.0` is ezhttp v0.22.0:

```
import ezhttp@0.22.0.0/main.bend as Http
```

That name resolves to `0xedb2120a04a47dc18c3a756ec7c62750`.
To pin by content instead, import `0xedb2120a04a47dc18c3a756ec7c62750/main.bend`.

Or with [ez](https://github.com/Emerging-Patterns/ez), which records the
package in `ez.toml` (`ez init` makes one):

```
ez add Emerging-Patterns/ezhttp
```

## Usage

Shared types cover both sides: `Header`, structured `Request` / `Reply`
(status or method, headers, body). Request bodies are empty, UTF-8 text, or
packed octets (bend-kit-bytes `Bytes`). The HTTP API does not need JSON: `Request`, `Reply`, and the client
`Response` stay text and octets, and `encode` / `decode` take any codec. The
hub package is the HTTP library alone. `src/json.bend`, the optional
helper that calls [ezjson](https://github.com/Emerging-Patterns/ezjson), is
in this repository but not reachable from `main.bend`, so it is not in the
hub package; import ezjson from the hub to read a JSON body (below).

### Client

`http.get`, `http.head`, `http.post`, `http.put`, `http.delete`, and
`http.options` return a structured client `Response`, or `Err` with why the
exchange failed. A `Response` has the status, the header fields and the status
line's reason phrase as text (decoded from what arrived as UTF-8, U+FFFD for a
byte that is not), and `bytes`: the body's octets exactly as they arrived,
packed (SPEC.md HTTP-BODY), so a binary download is byte-exact. The body is
never turned into text unless you ask: `body_text(bytes)` decodes it as UTF-8.
`Response` holds `Bytes`, so it is a linear value: match on it once.
Content-Length and chunk sizes count octets. A response is read and framed on
its packed octets, so a 20 MB download peaks near 100 MB rather than 1.35 GB.
An exchange that fails says why: a connection that could not be made names its
cause, such as `could not reach 127.0.0.1 port 1: ECONNREFUSED (111)`.
Pass custom headers: `bearer` writes `Authorization: Bearer …`, and `basic`
writes `Authorization: Basic …` (RFC 7617, RFC 4648). Sockets, TLS and
name resolution are [bend-kit](https://github.com/paymog/bend-kit)'s
(bend-kit-wire and bend-kit-dns, pinned by hash): `https` selects the TLS
path and port 443, and the certificate chain and host name are always
checked. OpenSSL 3 is loaded at run time; point `BEND_LIBSSL` at `libssl.so.3`
when it is not where the loader looks (`EZ_LIBSSL` is no longer read). Its
effects park on the runtime's event loop, so requests made under `IO.fork`
run side by side.

```
def status_and_text(r: Client.Response) -> String:
  match r:
    case Client.Err{why}:
      why
    case Client.Response{status, headers, reason, bytes}:
      U32.show(status) ++ " " ++ Http.body_text(bytes)
```

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/client.bend as Client
import ezhttp@0.22.0.0/src/body.bend as Body

def main() -> IO(Client.Response):
  Http.http.get("https://example.com/")

def authed() -> IO(Client.Response):
  Http.http.get_with("https://example.com/api", [Http.bearer("token")])

def create() -> IO(Client.Response):
  Http.http.put("https://example.com/items", Body.Plain{"hello"})
```

`http.get_opts(url, headers, timeout_ms, follow)` is a GET with a timeout in
milliseconds that bounds the connect, the TLS handshake and every send and
receive on its own (as httpx's does; name resolution, and a send over TLS,
are not bounded; a timeout of 0 is 1 ms). Every
other client function keeps its 60 s. Every client function stops reading as
soon as the response is complete by its framing (RFC 9112 §6.3: no body for
HEAD, 204 and 304, else chunked, else `Content-Length`), so a server that
keeps the connection open after a whole response is not waited on; only a
response with none of those framings is read until the server closes. A timeout comes back as `Err` with a
reason starting `timed out: `, and `http.timed_out(r)` tells it apart from
other failures. With `follow` set it follows 301, 302, 303, 307 and 308 for up
to 10 hops. Each hop is a GET with the same headers and timeout. A
`Location` is resolved against the current URL as RFC 3986 §5.2 resolves a
reference: an absolute `http(s)://` URL is taken as it is, `//host/...` keeps
the scheme, an absolute path keeps the scheme, host and port, and a query or
a relative path such as `web/` is merged with the current path, dot segments
removed. An empty `Location`, a fragment, or another scheme ends the chain. The
caller's headers go to every hop, credentials included, so only follow
redirects from hosts you trust with them. SPEC.md lists these guarantees
(HTTP-CLI, HTTP-REDIR). They are new after ezhttp 0.10.0.

```
def probe(url: String) -> IO(Client.Response):
  Http.http.get_opts(url, [], 5000, True{})
```

`http.request_opts(method, url, headers, body, timeout_ms, follow)` is the
same for any method, and `http.post_opts`, `http.put_opts` and
`http.delete_opts(url, headers, body, timeout_ms)` are it for POST, PUT and
DELETE. Only a GET follows redirects: any other method answers a redirect as
its response (no 303-to-GET).

Every request carries `Host`, `User-Agent: ezhttp`, `Accept: */*`,
`Connection: close` and, for a non-empty body, `Content-Length`. A header you
pass whose name (compared case-insensitively) is `Host`, `User-Agent` or
`Accept` replaces that default, so a server sees one `User-Agent`, yours.
`Connection` and `Content-Length` are not overridable: yours are dropped,
since the client frames the exchange by `Connection: close` and computes the
length from the body. Every other header is sent as you gave it, in order
(SPEC.md HTTP-CLI-8).

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/client.bend as Client
import ezhttp@0.22.0.0/src/http.bend as Msg
import ezhttp@0.22.0.0/src/body.bend as Body

def ingest(url: String, json: String) -> IO(Client.Response):
  Http.http.post_opts(url,
    [Msg.H{"User-Agent", "my-app/1"}, Msg.H{"Content-Type", "application/json"}],
    Body.Plain{json}, 10000)
```

A body is text (`text_body`, sent as its UTF-8) or octets (`octets_body` of
a bend-kit-bytes `Bytes`, or `octets_list_body` of a list of values 0 to 255),
sent byte for byte after the request head, with `Content-Length` counting
them (SPEC.md HTTP-CLI-10), so binary uploads reach the server unchanged. `form_body(boundary, parts)` builds a
`multipart/form-data` body (RFC 7578) from `form_field(name, value)` and
`form_file(name, filename, content_type, bytes)` parts: it answers the
`Content-Type` value to send and an octet body, or refuses a boundary that is
not 1 to 70 of `A-Z a-z 0-9 - _ .`, one whose `--boundary` occurs in a part's
content, and a file content type holding CR or LF (SPEC.md HTTP-FORM). Names
and filenames have `"`, CR and LF written as `%22`, `%0D` and `%0A`. A file's
content is `Bytes` (bend-kit-files' `read_bytes`, for example) and is sent
unchanged; the builder searches it for the delimiter with `Bytes.find`.

```
import bend-kit-bytes@0.3.2.0/bytes.bend as Bytes
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/client.bend as Client
import ezhttp@0.22.0.0/src/http.bend as Msg
import ezhttp@0.22.0.0/src/form.bend as Form

def upload(url: String, key: String, f: Form.Form) -> IO(Client.Response):
  match f:
    case Form.NoForm{why}:
      IO.pure(Client.Response, Client.Err{why})
    case Form.Form{ctype, body}:
      Http.http.post_opts(url, [Msg.H{"Content-Type", ctype}, Http.bearer(key)],
        body, 120000)

def transcribe(url: String, key: String, wav: Bytes.Bytes)
  -> IO(Client.Response):
  upload(url, key, Http.form_body("ezhttp-whisper-7d1f",
    [Http.form_field("model", "whisper"),
     Http.form_file("file", "audio.wav", "audio/wav", wav)]))
```

The client reads a response with its request's method in mind (SPEC.md
HTTP-CLI-9): interim 1xx responses such as `100 Continue` are skipped, and a
response to HEAD, or with a 1xx, 204 or 304 status, has an empty body
whatever its `Content-Length` or `Transfer-Encoding` say.
`parse_response_to(method, raw)` is that reading; `parse_response(raw)` does
not know the method and frames every body by its fields.

### Server

`http.serve(handle, host, port, limit)` listens on `host` (`"127.0.0.1"` for
loopback only, `"0.0.0.0"` for every interface), accepts connections, and
serves each one on its own fork: it parses one request, calls a pure handler,
and writes one response (`Connection: close`). Connections overlap, so a slow
handler does not hold up the next client (20 concurrent requests to a 0.5 s
handler take 0.5 s). It stops accepting after `limit` connections and returns
once they are all closed. `http.serve_once(handle, host, port)` stops after a
single client. No TLS for the server. A request that does not parse is
answered `400` with its reason and never reaches the handler. A response to
HEAD, and a 204 or 304, is written with an empty body. The request reaches
the handler as text (decoded from the octets that arrived as UTF-8).

A connection that fails (a failed accept, recv or send, such as a client resetting
mid-request) is closed and logged to stderr as one line, `ezhttp: <phase>: <why>`; it
counts toward `limit`. SPEC.md lists these guarantees (HTTP-SRV) and what is trusted
rather than proved.

`http.serve_with(~C, handle, ctx, host, port, limit, max)`,
`http.serve_io_with` and `http.serve_forever_with` take a context value
`ctx: C` that every call of the handler gets, and a concurrency limit `max`
(0: none). Their handler takes `(ctx, req)`, where `req` is a `Server.Req`:
the request as text and `bytes`, its body's octets exactly as they arrived.
It answers a `Server.Answer`: `text_reply(status, headers, body)` (UTF-8),
`octets_reply(status, headers, bytes)` (packed octets written unchanged), or
`stream_reply(status, headers, chan)`, written chunked as a producer sends
`Bytes` on the channel, until it closes the channel, so a large reply is
written in flat memory. The plain serves are these with a text handler.

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/server.bend as Server
import ezhttp@0.22.0.0/src/http.bend as Msg

# echo the body back byte for byte, with the context in a header
def echo(tag: String, req: Server.Req) -> Server.Answer:
  Server.Req{method, target, headers, body, bytes} = req
  Http.octets_reply(200, [Msg.H{"X-Tag", tag}], bytes)

def main() -> IO(Unit):
  Http.http.serve_with(~String, ~echo, "v1", "127.0.0.1", 8080, 1000, 64)
```

A handler that needs IO (a file, a subprocess, an upstream call) goes to
`http.serve_io(handle, host, port, limit)`, with `handle: Msg.Request -> IO(Msg.Reply)`.
`http.serve_forever(handle, host, port)` is the same with no limit, for a long-running
service; it is `@unsafe` recursion, so a program calling it is not proof-clean.

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/http.bend as Msg

def handle(req: Msg.Request) -> Msg.Reply:
  match req:
    case Msg.Bad{why}:
      Msg.Reply{400, [], why}
    case Msg.Request{method, target, headers, body}:
      Msg.Reply{200, [], "ok"}

def main() -> IO(Unit):
  Http.http.serve(handle, "127.0.0.1", 8080, 1024)
```

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/http.bend as Msg

def handle(req: Msg.Request) -> IO(Msg.Reply):
  match req:
    case Msg.Bad{why}:
      IO.pure(Msg.Reply, Msg.Reply{400, [], why})
    case Msg.Request{method, target, headers, body}:
      IO.bind(Unit, Msg.Reply, IO.print("served " ++ target),
        _u => IO.pure(Msg.Reply, Msg.Reply{200, [], "ok"}))

def main() -> IO(Unit):
  Http.http.serve_io(handle, "127.0.0.1", 8080, 1024)
```

Cookies, `Cache-Control`, and CORS are pure helpers on the same messages.

```
import ezhttp@0.22.0.0/main.bend as Http
import ezhttp@0.22.0.0/src/http.bend as Msg
import ezhttp@0.22.0.0/src/cookie.bend as Cookie
import ezhttp@0.22.0.0/src/cors.bend as Cors

def authed() -> Msg.Header:
  Http.basic("user", "pass")

def jar() -> Msg.Header:
  Http.cookie_header([Cookie.cookie.new("a", "b")])

def cacheable(value: String) -> Bool:
  Http.fresh(value, 0n)

def cross(cfg: Cors.Cfg, req: Msg.Request, reply: Msg.Reply) -> Msg.Reply:
  Http.cors_reply(cfg, req, reply)
```

```
import ezjson@1.2.0.0/main.bend as Ezjson
import ezjson@1.2.0.0/src/value.bend as Value

def read.of(got: Maybe<&2, Value.Json>) -> Maybe<&2, String>:
  match got:
    case None{}:
      None{}
    case Some{j}:
      Ezjson.as_str(j)

def read(text: String) -> Maybe<&2, String>:
  read.of(Ezjson.parse(text))
```

`quote_path` and `quote_component` percent-encode text for a URL (RFC 3986
§2.1) the way Python's `urllib.parse.quote(s)` and `quote(s, safe="")` do:
unreserved characters stay, every other character becomes `%XX` per UTF-8
byte in upper-case hex, and `/` stays in a path but is `%2F` in a component.
SPEC.md lists these guarantees (HTTP-URL). They are new after ezhttp 0.9.0.

```
import ezhttp@0.22.0.0/main.bend as Http

def search(q: String) -> String:
  "https://example.com/search?q=" ++ Http.quote_component(q)
```

`html_escape` escapes text for HTML as markupsafe and Jinja's autoescape do:
`&`, `<`, `>`, `"` and `'` become `&amp;`, `&lt;`, `&gt;`, `&#34;` and
`&#39;`, and every other character stays (HTTP-HTML). It is new after ezhttp
0.10.0.

`unquote` and `unquote_plus` percent-decode text the way Python's
`urllib.parse.unquote` and `unquote_plus` do: `%XX` (either case) becomes a
byte, an escape that is not two hex digits stays as written, characters
outside ASCII stay, and the bytes are read as UTF-8 with U+FFFD for each
ill-formed part (Python's `errors="replace"`). `quote_plus` is
`quote_component` with a space as `+`. `urlencode(pairs)` and
`parse_query(text)` write and read `application/x-www-form-urlencoded` query
strings as `urlencode` and `parse_qsl(text, keep_blank_values=True)` do: a
pair is `(name, value)`, `parse_query` keeps every pair in order (duplicates
and blank values included), and `query_get(pairs, name)` answers the last
value for a name (HTTP-QS). They are new after ezhttp 0.14.0.

```
import ezhttp@0.22.0.0/main.bend as Http

def page(query: String) -> Maybe<&2, String>:
  Http.query_get(Http.parse_query(query), "page")

def link(q: String) -> String:
  "/search?" ++ Http.urlencode([("q", q), ("page", "2")])
```

`html_unescape` turns character references back into characters as Python's
`html.unescape` does: decimal and hex numeric references with the HTML
Standard's replacements, and all 2231 of its named references (the legacy
ones also without `;`, read by longest match). It undoes `html_escape`
(HTTP-REF). `cookie_from_set_cookies(values)` and
`cookie_from_headers(headers)` give the `Cookie` header value to send back
after `Set-Cookie` fields: each one's `name=value` (RFC 6265 §5.2), no
attributes, a later cookie with the same name replacing the earlier one's
value in place, joined by `; ` (§5.4) (HTTP-CK). Both are new after
ezhttp 0.14.0.

`parse_cookie` reads a `Set-Cookie` field value. `set_cookie` writes one.
`cache_control` reads `no-store`, `no-cache`, `max-age`, `public`, and
`private`. `cors_reply` answers a simple request or an OPTIONS preflight from
`allow_origins`, methods, headers, credentials, and `max_age`. Credentials
never pair with `Access-Control-Allow-Origin: *`.

## Compliance

Closed equalities in `LAWS.bend`, proved in `PROOF.bend`
(`bend PROOF.bend` prints `ALL PROOFS CHECK`). `main.bend` and
`src/client.bend` reach the wire effect, so no law file imports them: the
laws are stated on the pure definitions under `src/`, and each re-export in
`main.bend` that bolt's `coverage` rule (an error) would flag carries a
`# noqa: L001` naming the definition it re-exports. The laws target:

- [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986) URI: scheme before the
  first colon and lowercased (§3.1), `hier-part` requiring `//` (§3),
  userinfo stripped from the authority, last `@` wins (§3.2.1), IPv4 host and
  explicit port, a non-numeric port uses the scheme default (§3.2.2, §3.2.3),
  path always absolute, trailing slash kept (§3.3), query kept including a
  later `?`, fragment dropped even when it holds `?` (§3.4, §3.5), default
  ports 80 / 443. Percent-encoding: unreserved characters (§2.3) written
  as themselves, everything else as `%XX` per UTF-8 byte (RFC 3629 §3),
  upper-case hex (§2.1).
- [RFC 2818](https://www.rfc-editor.org/rfc/rfc2818) HTTP over TLS: scheme
  `https` selects the TLS wire path and port 443. The TLS handshake itself
  is bend-kit-wire's.
- [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110) HTTP Semantics:
  case-insensitive field names (§5.1), optional whitespace trimmed and
  obs-fold rejected (§5.5), `Host` on every HTTP/1.1 client request, with
  the port when it is not the scheme's default (§7.2),
  `Content-Length` as an exact octet count, omitted when the body is empty
  (§8.6), the first of a repeated field is the one lookup returns (§5.2),
  safe methods GET / HEAD / OPTIONS (§9.2.1), idempotent methods adding PUT /
  DELETE (§9.2.2), method tokens case-sensitive (§9.3), HEAD response body
  omitted (§9.3.2), PUT / DELETE / OPTIONS request lines (§9.3.4, §9.3.5,
  §9.3.7), reason-phrases for 200, 201, 202, 204, 301, 302, 303, 304, 307,
  308, 400, 401, 403, 404, 405, 409, 410, 413, 415, 422, 429 (RFC 6585 §4),
  500, 501, 502, 503 and 504 (§15).
  A 204 or 304 response is written with an empty body (§15.3.5, §15.4.5).
- [RFC 9112](https://www.rfc-editor.org/rfc/rfc9112) HTTP/1.1 Message Syntax
  and Routing: header section ended by a blank line (§2.1), origin-form
  request-target (§3.2.1), `OPTIONS *` asterisk-form (§3.2.4), status-line
  `HTTP/1.1` (§4), `Content-Length` values that disagree and
  `Content-Length` together with `Transfer-Encoding` are rejected, while
  identical `Content-Length` values are that one length (§6.3), chunked
  bodies including a second non-empty chunk, a chunk-ext, a non-hex chunk
  size, and a size of 0 that ends the body before any trailer (§7.1),
  `Connection: close` (§9.6). A body shorter than its `Content-Length` is
  torn (client response) or bad (server request). Absolute-form is rejected.
  The client skips interim 1xx responses (RFC 9110 §15.2) and reads no body
  for a reply to HEAD or a 1xx, 204 or 304 status (§6.3 item 1).
- [RFC 7578](https://www.rfc-editor.org/rfc/rfc7578) multipart/form-data:
  each part framed by `--boundary` CRLF, its `Content-Disposition: form-data;
  name="…"` line (with `filename="…"` and a `Content-Type` line for a file),
  a blank line, its content and CRLF, closed by `--boundary--` CRLF (§4.1,
  §4.2, §4.4; RFC 2046 §5.1.1); `"`, CR and LF in a name percent-encoded; a
  boundary that occurs in a part is refused.
- [RFC 4648](https://www.rfc-editor.org/rfc/rfc4648) Base64 (§4, §10) and
  [RFC 7617](https://www.rfc-editor.org/rfc/rfc7617) Basic authentication
  (§2): `Authorization: Basic` is Base64 of `user:password`.
- [RFC 6750](https://www.rfc-editor.org/rfc/rfc6750) Bearer (§2.1):
  `Authorization: Bearer` plus a token with no whitespace.
- [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265) cookies: `Set-Cookie`
  name=value and attributes Expires, Max-Age, Domain, Path, Secure, HttpOnly,
  SameSite (§4.1.1, canonical Lax / Strict / None; anything else is dropped),
  domain-match and path-match (§5.1.3, §5.1.4), the `Cookie` request header
  joined by `; ` (§5.4). An empty cookie-name is rejected. A non-digit
  Max-Age is ignored. Domain is stored lowercase. Expires is stored and not
  compared to a clock. SameSite is stored; there is no browsing context to
  suppress a cross-site send.
- [RFC 9111](https://www.rfc-editor.org/rfc/rfc9111) HTTP Caching: `max-age`
  freshness, including `max-age=0` stale (§4.2.1), `Cache-Control` directives
  `no-store`, `no-cache`, `max-age`, `public`, `private` with case-insensitive
  names (§5.2). An unrecognized directive such as `s-maxage`, and a
  non-digit `max-age`, are ignored. `Expires` is recorded beside
  Cache-Control (§5.3). This is not a shared cache.
- [Fetch CORS protocol](https://fetch.spec.whatwg.org/#cors-protocol):
  `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`,
  `Access-Control-Allow-Headers`, `Access-Control-Allow-Credentials`,
  `Access-Control-Max-Age`, `Access-Control-Expose-Headers`, and the request
  headers `Origin`, `Access-Control-Request-Method`,
  `Access-Control-Request-Headers`. A small allow-list answers a simple
  request and an OPTIONS preflight. Requested header names are matched
  case-insensitively. A refused origin, method, or header is a 400 preflight.
  Credentials never emit `*`.

Not claimed: HTTP/2 (RFC 9113), HTTP/3 (RFC 9114), a TLS handshake in the
server, multipart bodies, pipelining, trailers, 1xx / `Expect`, a shared
cache or IMF-fixdate arithmetic, a full cookie jar (public suffix, eviction,
the Expires clock, SameSite cross-site suppression), `allow_origin_regex`,
IPv6 literals, absolute-form request-targets, and unfolding
obs-fold (it is rejected). Userinfo is stripped, not turned into
`Authorization`.
