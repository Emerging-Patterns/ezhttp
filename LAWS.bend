# ezhttp: the laws. Closed equalities for URL parsing (RFC 3986), HTTP/1.1
# message framing (RFC 9112), HTTP semantics (RFC 9110), TLS selection
# (RFC 2818), Basic and Bearer credentials (RFC 7617, RFC 4648, RFC 6750),
# cookies (RFC 6265), caching directives (RFC 9111), and Fetch CORS.
# PROOF.bend fills them. `bend PROOF.bend` is the gate.
import Base
import ./src/http.bend as Http
import ./src/url.bend as Url
import ./src/body.bend as Body
import ./src/auth.bend as Auth
import ./src/wirespec.bend as Spec
import ./src/b64.bend as B64
import ./src/cookie.bend as Cookie
import ./src/cache.bend as Cache
import ./src/cors.bend as Cors
import ./src/json.bend as Json
import ./src/step.bend as Step
import ./src/pct.bend as Pct
import ./src/html.bend as Html
import ./src/redirect.bend as Redirect
import ./src/form.bend as Form
import 0xa81e161008ecc2f297c0a3065cb9b188/main.bend as Ezjson

# LAW (RFC 3986 §3.3 path-absolute / path-abempty with authority): the path a
# URL comes apart into is always absolute. The request-target is an
# absolute-path (RFC 9112 §3.2.1).
law path_absolute:
  for ps: List<&2, String>
  {String.starts_with(Url.path.of(ps), "/") == True{} : Bool}

# LAW: take and drop partition a string at the same UTF-8 byte offset
# (Content-Length octets, RFC 9110 §8.6).
law utf8_split:
  for s: String
  for +n: Nat
  {String.append(Http.utf8.take(s, n), Http.utf8.drop(s, n)) == s : String}

# LAW (RFC 9110 §8.6 / RFC 9112 §6.3): a body whose Content-Length is its own
# octet count comes back exactly.
law clen_exact:
  for st: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.parse.clen(st, hs, Http.utf8.len(body), body)
    == Http.Reply{st, hs, body} : Http.Reply}

# LAW (RFC 9112 §6.3): a body shorter than its Content-Length is torn — a cut
# connection is not a short file.
law clen_short:
  for st: U32
  for hs: List<&2, Http.Header>
  for +n: Nat
  for +body: String
  for e: {True{} == Nat.is_lt(Http.utf8.len(body), n) : Bool}
  {Http.parse.clen(st, hs, n, body)
    == Http.Torn{"the response body stopped before its Content-Length"}
    : Http.Reply}

# whether a string holds a character nowhere
def avoids(s: String, +c: Char) -> Bool:
  match s:
    case SNil{}:
      True{}
    case SCon{+h, t}:
      Bool.and(Bool.not(Char.is_eq(h, c)), avoids(t, c))

# LAW: a string that holds the character nowhere splits into itself
law split_whole:
  for +s: String
  for +c: Char
  for +e: {avoids(s, c) == True{} : Bool}
  {String.split(s, c) == [s] : List<&2, String>}

# LAW: a string that holds the character first at a known place splits there
law split_cut:
  for +s: String
  for +c: Char
  for +r: String
  for +e: {avoids(s, c) == True{} : Bool}
  {String.split(String.append(s, SCon{c, r}), c) == s <> String.split(r, c)
    : List<&2, String>}

# LAW (RFC 9112 §7.1): an empty chunked body decodes to empty
law dechunk_empty:
  {Http.dechunk("") == "" : String}

# LAW (RFC 9112 §7.1): no fuel left means no more chunks
law chunks_empty_fuel:
  {Http.chunks(0n, Http.NoCut{}) == "" : String}

# LAW (RFC 9112 §7.1): a chunk-size extension after `;` does not change the
# length hexlen reads.
law hexlen_ignores_extension:
  for +s: String
  for ext: String
  for +e: {avoids(s, ';') == True{} : Bool}
  {Http.hexlen(String.append(s, SCon{';', ext})) == Http.hexlen(s) : Nat}

# LAW: the first piece of a line split on a space is the word before it
law first_is_first_word:
  for +w: String
  for r: String
  for +e: {avoids(w, ' ') == True{} : Bool}
  {Http.first(String.split(String.append(w, SCon{' ', r}), ' ')) == w : String}

# LAW: the second piece is the first word of what follows (status code on
# `HTTP/1.1 200 OK`, RFC 9112 §4)
law second_is_next_word:
  for +w: String
  for r: String
  for +e: {avoids(w, ' ') == True{} : Bool}
  {Http.second(String.split(String.append(w, SCon{' ', r}), ' '))
    == Http.first(String.split(r, ' ')) : String}

# LAW (RFC 9112 §3.2.1): the request-line opens with the method it was given
law request_names_method:
  for +method: String
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.request(method, host, path, hs, body), method)
    == True{} : Bool}

# LAW: GET request-line opens with GET and the path
law get_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.get_req(host, path, hs), "GET " ++ path)
    == True{} : Bool}

# LAW: HEAD request-line opens with HEAD and the path (RFC 9110 §9.3.2)
law head_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.head_req(host, path, hs), "HEAD " ++ path)
    == True{} : Bool}

# LAW: POST request-line opens with POST and the path
law post_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: Body.Body
  {String.starts_with(Http.post_req(host, path, hs, body), "POST " ++ path)
    == True{} : Bool}

# LAW (RFC 9112 §2.1): a response whose header section never ended is torn
law parse_needs_blank_line:
  for +raw: String
  for e: {Http.NoCut{} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.parse(raw) == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}

# LAW: when the head did end, parse uses everything before/after the blank line
# HTTP-CLI-9
law parse_splits_at_blank_line:
  for +raw: String
  for before: String
  for after: String
  for e: {Http.Cut{before, after} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.parse(raw) == Http.parse.head(String.lines(before), after)
    : Http.Reply}

# LAW (RFC 9112 §6.3): with neither framing header the rest of the connection
# is the body (Connection: close)
law unframed_is_rest:
  for st: U32
  for hs: List<&2, Http.Header>
  for body: String
  {Http.parse.len(st, hs, None{}, body) == Http.Reply{st, hs, body}
    : Http.Reply}

# LAW (RFC 9110 §5.1): field names are compared case-insensitively
law head_hit_ignores_case:
  for +h: String
  for +name: String
  {Http.head.hit(h, name)
    == String.starts_with(String.to_lower(h), name ++ ":") : Bool}

# LAW (RFC 9112 §4): a head whose first line holds no status code is torn
law parse_needs_status:
  for +ls: List<&2, String>
  for body: String
  for e: {None{} == U32.read(Http.second(String.split(Http.first(ls), ' ')))
    : Maybe<&2, U32>}
  {Http.parse.head(ls, body)
    == Http.Torn{"the response has no status line"}
    : Http.Reply}

# LAW: a torn response says so before it says anything else
law show_torn_is_marked:
  for why: String
  {String.starts_with(Http.show(Http.Torn{why}), "torn ") == True{} : Bool}

# LAW: a reply opens with the status it holds
law show_reply_opens_with_status:
  for +status: U32
  for hs: List<&2, Http.Header>
  for body: String
  {String.starts_with(Http.show(Http.Reply{status, hs, body}), U32.show(status))
    == True{} : Bool}

# LAW (RFC 9112 §4): a response message opens with HTTP/1.1
law respond_opens_with_version:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.respond(status, hs, body), "HTTP/1.1 ")
    == True{} : Bool}

# LAW (RFC 9112 §4): 200 uses the OK reason-phrase
law reason_200:
  {Http.reason(200) == "OK" : String}

# LAW (RFC 9112 §2.1): a request whose header section never ended is bad
law ask_needs_blank_line:
  for +raw: String
  for e: {Http.NoCut{} == Http.divide(raw, "\r\n\r\n") : Http.Cut}
  {Http.ask(raw) == Http.Bad{"the request head has no blank line after it"}
    : Http.Request}

# LAW (RFC 9112 §3): an empty request-line list is bad
law ask_needs_request_line:
  for body: String
  {Http.ask.head([], body) == Http.Bad{"the request has no request line"}
    : Http.Request}

# LAW (RFC 9110 §8.6): a request body whose Content-Length matches comes back
law ask_clen_exact:
  for +method: String
  for +target: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.ask.clen(method, target, hs, Http.utf8.len(body), body)
    == Http.Request{method, target, hs, body} : Http.Request}

# LAW: a request body shorter than Content-Length is bad
law ask_clen_short:
  for +method: String
  for +target: String
  for hs: List<&2, Http.Header>
  for +n: Nat
  for +body: String
  for e: {True{} == Nat.is_lt(Http.utf8.len(body), n) : Bool}
  {Http.ask.clen(method, target, hs, n, body)
    == Http.Bad{"the request body stopped before its Content-Length"}
    : Http.Request}

# LAW: a bad request show is marked
law ask_show_bad_is_marked:
  for why: String
  {String.starts_with(Http.ask.show(Http.Bad{why}), "bad ") == True{} : Bool}

# LAW (RFC 3986 §3.2.3): only https implies 443; other schemes get 80
law dflt_plain:
  for +scheme: String
  for e: {False{} == String.eq(scheme, "https") : Bool}
  {Url.dflt(scheme) == 80 : U32}

# LAW: https implies 443
law dflt_https:
  {Url.dflt("https") == 443 : U32}

# LAW (RFC 3986 §3.1): the scheme is everything before the first colon
law parse_scheme_first:
  for +url: String
  for h: String
  for t: List<&2, String>
  for e: {h <> t == String.split(url, ':') : List<&2, String>}
  {Url.parse(url) == Url.parse.rest(String.to_lower(h), String.join(t, ":"))
    : Url.Loc}

# LAW (RFC 3986 §3): hier-part without "//" is refused
law parse_needs_slashes:
  for +scheme: String
  for +rest: String
  for e: {False{} == String.starts_with(rest, "//") : Bool}
  {Url.parse.rest(scheme, rest)
    == Url.Bad{scheme ++ ":" ++ rest ++ " has no //"}
    : Url.Loc}

# LAW: a url that would not come apart says so first
law url_show_bad_is_marked:
  for why: String
  {String.starts_with(Url.show(Url.Bad{why}), "bad ") == True{} : Bool}

# LAW: a url that came apart opens with its scheme
law url_show_opens_with_scheme:
  for +scheme: String
  for host: String
  for port: U32
  for path: String
  {String.starts_with(Url.show(Url.Loc{scheme, host, port, path}), scheme)
    == True{} : Bool}

# --- main API surface (named so bolt laws stay clean) ---

# LAW: bearer builds Authorization: Bearer …
law bearer_is_authorization:
  for token: String
  {Auth.auth.bearer(token) == Http.H{"Authorization", "Bearer " ++ token}
    : Http.Header}

# --- RFC 3986 authority, query, fragment ---

# LAW (RFC 3986 §3.3): an empty path-abempty is the origin-form `/`
law url_empty_path:
  {Url.parse("http://example.com")
    == Url.Loc{"http", "example.com", 80, "/"} : Url.Loc}

# LAW (RFC 3986 §3.2.2): an IPv4 literal is the host
law url_ipv4_host:
  {Url.parse("http://192.0.2.1/a")
    == Url.Loc{"http", "192.0.2.1", 80, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.2.3): an explicit port wins over the scheme default
law url_ipv4_port:
  {Url.parse("http://192.0.2.1:8080/a")
    == Url.Loc{"http", "192.0.2.1", 8080, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.2.1): userinfo is stripped; it is not the host
law url_userinfo_stripped:
  {Url.parse("http://user:pass@example.com/a")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.4, §3.5): the query stays on the path; the fragment does not
law url_query_drops_fragment:
  {Url.parse("http://example.com/a/b?x=1#frag")
    == Url.Loc{"http", "example.com", 80, "/a/b?x=1"} : Url.Loc}

# LAW (RFC 3986 §3.3, §3.4): an empty path with a query is `/?query`
law url_query_on_empty_path:
  {Url.parse("http://example.com?x=1")
    == Url.Loc{"http", "example.com", 80, "/?x=1"} : Url.Loc}

# LAW (RFC 3986 §3.1): the scheme is lowercased; the host is not
law url_scheme_lowercased:
  {Url.parse("HTTPS://Example.com/x")
    == Url.Loc{"https", "Example.com", 443, "/x"} : Url.Loc}

# LAW (RFC 3986 §3.2.3 / RFC 2818): https with no port is 443
law url_https_default_port:
  {Url.parse("https://example.com/a")
    == Url.Loc{"https", "example.com", 443, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.2.3): an explicit https port is kept
law url_https_explicit_port:
  {Url.parse("https://example.com:8443/a")
    == Url.Loc{"https", "example.com", 8443, "/a"} : Url.Loc}

# --- RFC 2818: https selects the TLS path at the wire ---

# LAW (RFC 2818): a secure exchange is labeled tls, on the given port
law wire_https_is_tls:
  {Spec.wire.spec(True{}, "example.com", 443, "GET / HTTP/1.1\r\n\r\n")
    == "tls\nexample.com\n443\nGET / HTTP/1.1\r\n\r\n" : String}

# LAW: a cleartext exchange is labeled tcp
law wire_http_is_tcp:
  {Spec.wire.spec(False{}, "example.com", 80, "GET / HTTP/1.1\r\n\r\n")
    == "tcp\nexample.com\n80\nGET / HTTP/1.1\r\n\r\n" : String}

# --- RFC 9112 request and response writers ---

# LAW (RFC 9112 §4, §9.6): a response status-line is HTTP/1.1 plus the
# reason-phrase, and the connection closes
# HTTP-SRV-5
law respond_writes_reason_and_close:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.respond(status, hs, body)
    == "HTTP/1.1 " ++ U32.show(status) ++ " " ++ Http.reason(status) ++ "\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n"
      ++ body
    : String}

# LAW (RFC 9110 §9.3.4): PUT request-line opens with PUT and the path
law put_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: Body.Body
  {String.starts_with(Http.put_req(host, path, hs, body), "PUT " ++ path)
    == True{} : Bool}

# LAW (RFC 9110 §9.3.5): DELETE request-line opens with DELETE and the path
law delete_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: Body.Body
  {String.starts_with(Http.delete_req(host, path, hs, body), "DELETE " ++ path)
    == True{} : Bool}

# LAW (RFC 9110 §9.3.7): OPTIONS request-line opens with OPTIONS and the path
law options_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.options_req(host, path, hs), "OPTIONS " ++ path)
    == True{} : Bool}

# LAW (RFC 9110 §9.3): method tokens are case-sensitive
law method_tokens_are_case_sensitive:
  {String.eq("GET", "get") == False{} : Bool}

# LAW (RFC 9110 §9.2.1): GET, HEAD, and OPTIONS are safe; `get` is not GET
law method_safe_get:
  {Http.method.safe("GET") == True{} : Bool}

# LAW: a lower-case get is not the safe method GET
law method_safe_get_lower:
  {Http.method.safe("get") == False{} : Bool}

# LAW: POST is not safe
law method_safe_post:
  {Http.method.safe("POST") == False{} : Bool}

# LAW (RFC 9110 §9.2.2): PUT is idempotent
law method_idempotent_put:
  {Http.method.idempotent("PUT") == True{} : Bool}

# LAW: DELETE is idempotent
law method_idempotent_delete:
  {Http.method.idempotent("DELETE") == True{} : Bool}

# LAW: OPTIONS is idempotent because it is safe
law method_idempotent_options:
  {Http.method.idempotent("OPTIONS") == True{} : Bool}

# LAW: POST is not idempotent
law method_idempotent_post:
  {Http.method.idempotent("POST") == False{} : Bool}

# LAW (RFC 9110 §15.5.1): 400 Bad Request
law reason_400:
  {Http.reason(400) == "Bad Request" : String}

# LAW (RFC 9110 §15.5.5): 404 Not Found
law reason_404:
  {Http.reason(404) == "Not Found" : String}

# LAW (RFC 9110 §15.6.1): 500 Internal Server Error
law reason_500:
  {Http.reason(500) == "Internal Server Error" : String}

# LAW (RFC 9110 §9.3.2): a HEAD response is written with an empty body
law head_reply_drops_body:
  {Http.reply.for("HEAD", Http.Reply{200, [], "secret"})
    == Http.Reply{200, [], ""} : Http.Reply}

# LAW: any other method keeps the response body
law get_reply_keeps_body:
  {Http.reply.for("GET", Http.Reply{200, [], "secret"})
    == Http.Reply{200, [], "secret"} : Http.Reply}

# LAW (RFC 9110 §5.5): OWS around a field value is trimmed
law head_line_trims:
  {Http.head.line("A:  b  ") == Some{Http.H{"A", "b"}} : Maybe<&2, Http.Header>}

# LAW (RFC 9112 §5.2): a field value that still holds obs-fold is rejected
law head_line_rejects_obs_fold:
  {Http.head.line("A: b\r\n c") == None{} : Maybe<&2, Http.Header>}

# LAW: a continuation line with no colon is not a field
law head_line_rejects_continuation:
  {Http.head.line(" folded") == None{} : Maybe<&2, Http.Header>}

# LAW (RFC 9112 §3.2.1): a request-target without a leading `/` is not
# origin-form
law ask_rejects_relative_target:
  {Http.ask("GET relative HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}

# LAW (RFC 9112 §3.2.1): origin-form keeps an absolute-path and its query
law ask_origin_form_keeps_query:
  {Http.ask("GET /ok?a=1 HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Request{"GET", "/ok?a=1", [Http.H{"Host", "h"}], ""} : Http.Request}

# LAW (RFC 9112 §6.3): Content-Length and Transfer-Encoding together are torn
law parse_rejects_cl_and_te:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n")
    == Http.Torn{"Content-Length and Transfer-Encoding conflict"} : Http.Reply}

# LAW (RFC 9112 §6.3): Content-Length values that differ are a bad request
law ask_rejects_disagreeing_cl:
  {Http.ask("GET / HTTP/1.1\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\nab")
    == Http.Bad{"Content-Length values disagree"} : Http.Request}

# LAW (RFC 9112 §7.1): a non-hexadecimal chunk size is torn
law parse_rejects_non_hex_chunk:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nZ\r\n\r\n")
    == Http.Torn{"chunk size is not hexadecimal"} : Http.Reply}

# LAW (RFC 9112 §7.1): two non-empty chunks round-trip
law dechunk_two_chunks:
  {Http.dechunk("1\r\nZ\r\n2\r\nOK\r\n0\r\n\r\n") == "ZOK" : String}

# LAW (RFC 9112 §7.1): the chunked example wiki + pedia is wikipedia
law dechunk_wiki:
  {Http.dechunk("4\r\nwiki\r\n5\r\npedia\r\n0\r\n\r\n") == "wikipedia" : String}

# LAW (RFC 9110 §8.6): Content-Length takes that many octets and no more
law parse_clen_takes_prefix:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Reply{200, [Http.H{"Content-Length", "5"}], "hello"} : Http.Reply}

# LAW (RFC 9112 §7.1): a chunked response body is the concatenated chunks
law parse_chunked_body:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nwiki\r\n5\r\npedia\r\n0\r\n\r\n")
    == Http.Reply{200, [Http.H{"Transfer-Encoding", "chunked"}], "wikipedia"}
    : Http.Reply}

# --- RFC 6750 / 7617 / 4648 credentials ---

# LAW (RFC 6750 §2.1): a token with no whitespace is acceptable
law token_ok_plain:
  {Http.token.ok("abc") == True{} : Bool}

# LAW (RFC 6750 §2.1): a space is not a bearer token character
law token_ok_space:
  {Http.token.ok("a b") == False{} : Bool}

# LAW (RFC 6750 §2.1): a tab is not a bearer token character
law token_ok_tab:
  {Http.token.ok("a\tb") == False{} : Bool}

# LAW (RFC 4648 §4): the empty string encodes to empty
law b64_empty:
  {B64.b64.encode("") == "" : String}

# LAW (RFC 4648 §10): `f` encodes to `Zg==`
law b64_f:
  {B64.b64.encode("f") == "Zg==" : String}

# LAW (RFC 4648 §10): `fo` encodes to `Zm8=`
law b64_fo:
  {B64.b64.encode("fo") == "Zm8=" : String}

# LAW (RFC 4648 §10): `foo` encodes to `Zm9v`
law b64_foo:
  {B64.b64.encode("foo") == "Zm9v" : String}

# LAW (RFC 7617 §2): Basic credentials are Base64 of user:password
law basic_user_pass:
  {Auth.auth.basic("user", "pass")
    == Http.H{"Authorization", "Basic dXNlcjpwYXNz"} : Http.Header}

# --- RFC 6265 cookies ---

# LAW (RFC 6265 §4.1.1): attributes serialize with `; ` separators
law cookie_line_attributes:
  {Cookie.cookie.line(Cookie.Cookie{"a", "b",
      "Wed, 21 Oct 2015 07:28:00 GMT", "12", "example.com", "/app",
      True{}, True{}, "Lax", False{}})
    == "a=b; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Max-Age=12; Domain=example.com; Path=/app; Secure; HttpOnly; SameSite=Lax"
    : String}

# LAW (RFC 6265 §4.1.1): Set-Cookie parses back to those attributes
law cookie_parse_round_trip:
  {Cookie.cookie.parse("a=b; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Max-Age=12; Domain=example.com; Path=/app; Secure; HttpOnly; SameSite=Lax")
    == Some{Cookie.Cookie{"a", "b", "Wed, 21 Oct 2015 07:28:00 GMT", "12",
      "example.com", "/app", True{}, True{}, "Lax", False{}}}
    : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §4.1.1): an empty cookie-name is rejected
law cookie_rejects_empty_name:
  {Cookie.cookie.parse("=nope") == None{} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §5.4): the Cookie header joins pairs with `; ` and drops an
# empty name
law cookie_request_joins:
  {Cookie.cookie.join([Cookie.cookie.new("a", "b"), Cookie.cookie.new("c", "d"),
      Cookie.cookie.new("", "x")])
    == "a=b; c=d" : String}

# LAW (RFC 6265 §5.1.4): default-path is the directory of a path with two slashes
law cookie_default_path_dir:
  {Cookie.cookie.default_path("/a/b") == "/a" : String}

# LAW (RFC 6265 §5.1.4): fewer than two slashes means default-path `/`
law cookie_default_path_root:
  {Cookie.cookie.default_path("/a") == "/" : String}

# LAW (RFC 6265 §5.1.4): a trailing slash keeps the directory, not the slash
law cookie_default_path_trailing:
  {Cookie.cookie.default_path("/foo/bar/") == "/foo/bar" : String}

# LAW (RFC 6265 §5.4): a host-only cookie stores the response host and default-path
law cookie_receive_host_only:
  {Cookie.cookie.line(Cookie.cookie.receive("Example.COM", "/a/b",
      Cookie.cookie.new("a", "b")))
    == "a=b; Path=/a" : String}

# LAW (RFC 6265 §5.1.3): a domain-match allows a leading-dot suffix
law cookie_domain_suffix:
  {Cookie.cookie.domain_ok("www.example.com", "example.com", False{})
    == True{} : Bool}

# LAW (RFC 6265 §5.1.3): a suffix without the separating dot does not match
law cookie_domain_not_suffix:
  {Cookie.cookie.domain_ok("notexample.com", "example.com", False{})
    == False{} : Bool}

# LAW (RFC 6265 §5.1.3): an IPv4 host does not domain-match a suffix
law cookie_domain_ip_suffix:
  {Cookie.cookie.domain_ok("192.0.2.1", "2.1", False{}) == False{} : Bool}

# LAW (RFC 6265 §5.1.3): an IPv4 host matches its own address exactly
law cookie_domain_ip_exact:
  {Cookie.cookie.domain_ok("192.0.2.1", "192.0.2.1", False{}) == True{} : Bool}

# LAW (RFC 6265 §5.1.4): a path-match allows a prefix whose next character is `/`
law cookie_path_prefix:
  {Cookie.cookie.path_ok("/app/x", "/app") == True{} : Bool}

# LAW (RFC 6265 §5.1.4): a longer segment is not a path-match
law cookie_path_not_prefix:
  {Cookie.cookie.path_ok("/application", "/app") == False{} : Bool}

# LAW (RFC 6265 §5.4): a Secure cookie is not sent on a cleartext request
law cookie_secure_needs_tls:
  {Cookie.cookie.send.secure(False{}, True{}) == False{} : Bool}

# LAW (RFC 6265 §5.4): a Secure cookie is sent when the request is TLS
law cookie_secure_on_tls:
  {Cookie.cookie.send.secure(True{}, True{}) == True{} : Bool}

# LAW (RFC 6265 §5.4): Max-Age 0 is not alive at age 0
law cookie_max_age_zero:
  {Cookie.cookie.alive("0", 0n) == False{} : Bool}

# LAW (RFC 6265 §5.4): an age under Max-Age is still alive
law cookie_max_age_open:
  {Cookie.cookie.alive("10", 0n) == True{} : Bool}

# LAW (RFC 6265 §5.4): a session cookie (no Max-Age) stays sendable
law cookie_session_alive:
  {Cookie.cookie.alive("", 5n) == True{} : Bool}

# --- RFC 9111 cache directives ---

# LAW (RFC 9111 §5.2): directive names are case-insensitive
law cache_directive_case:
  {Cache.cache.parse("No-Store, MAX-AGE=0, Public")
    == Cache.Cc{True{}, False{}, True{}, False{}, "0", ""} : Cache.Cc}

# LAW (RFC 9111 §5.2): no-store, no-cache, public, private, and max-age
law cache_directives:
  {Cache.cache.parse("no-store, no-cache, public, private, max-age=5")
    == Cache.Cc{True{}, True{}, True{}, True{}, "5", ""} : Cache.Cc}

# LAW (RFC 9111 §4.2.1): max-age=0 is stale at age 0
law fresh_max_age_zero:
  {Cache.cache.fresh(Cache.cache.parse("max-age=0"), 0n) == False{} : Bool}

# LAW (RFC 9111 §4.2.1): an age under max-age is fresh
law fresh_max_age_open:
  {Cache.cache.fresh(Cache.cache.parse("max-age=10"), 0n) == True{} : Bool}

# LAW (RFC 9111 §4.2.1): an age equal to max-age is stale
law fresh_max_age_limit:
  {Cache.cache.fresh(Cache.cache.parse("max-age=10"), 10n) == False{} : Bool}

# LAW (RFC 9111 §5.2.2.2): no-cache is not fresh
law fresh_no_cache:
  {Cache.cache.fresh(Cache.cache.parse("no-cache, max-age=10"), 0n)
    == False{} : Bool}

# LAW (RFC 9111 §5.2.2.3): no-store is not fresh
law fresh_no_store:
  {Cache.cache.fresh(Cache.cache.parse("no-store, max-age=10"), 0n)
    == False{} : Bool}

# LAW (RFC 9111 §4.2.1): without max-age the response is not treated as fresh
law fresh_public_only:
  {Cache.cache.fresh(Cache.cache.parse("public"), 0n) == False{} : Bool}

# LAW (RFC 9111 §5.3): Expires is recorded beside Cache-Control
law cache_note_expires:
  {Cache.cache.note("max-age=0", "Wed, 21 Oct 2099 07:28:00 GMT")
    == Cache.Cc{False{}, False{}, False{}, False{}, "0",
      "Wed, 21 Oct 2099 07:28:00 GMT"} : Cache.Cc}

# LAW (RFC 9111 §4.2.1): max-age overrides Expires for freshness
law fresh_max_age_overrides_expires:
  {Cache.cache.fresh(Cache.cache.note("max-age=0",
      "Wed, 21 Oct 2099 07:28:00 GMT"), 0n) == False{} : Bool}

# LAW (RFC 9111 §4.2.1): a present max-age is what freshness uses
law cache_max_age_present:
  {Cache.cache.max_age(Cache.cache.parse("max-age=1")) == True{} : Bool}

# --- Fetch CORS (https://fetch.spec.whatwg.org/#cors-protocol) ---

# LAW (Fetch CORS): credentials reflect the request origin, never `*`
law cors_credentials_reflect_origin:
  {Cors.cors.acao(["*"], True{}, "https://app.example")
    == "https://app.example" : String}

# LAW (Fetch CORS): without credentials, `*` stays `*`
law cors_star_without_credentials:
  {Cors.cors.acao(["*"], False{}, "https://app.example") == "*" : String}

# LAW (Fetch CORS): an explicit allow-list reflects the matching origin
law cors_explicit_origin:
  {Cors.cors.acao(["https://app.example"], False{}, "https://app.example")
    == "https://app.example" : String}

# LAW (Fetch CORS): a missing origin is refused
law cors_refused_origin:
  {Cors.cors.acao(["https://ok.example"], False{}, "https://no.example")
    == "" : String}

# LAW (Fetch CORS): Vary is set when ACAO is a specific origin
law cors_vary_specific:
  {Cors.cors.vary("https://app.example") == True{} : Bool}

# LAW (Fetch CORS): Vary is not set for `*`
law cors_vary_star:
  {Cors.cors.vary("*") == False{} : Bool}

# LAW (Fetch CORS): Vary is not set when the origin was refused
law cors_vary_empty:
  {Cors.cors.vary("") == False{} : Bool}

# LAW (Fetch CORS): an allowed preflight is 200 with the CORS headers
law cors_preflight_allowed:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", "PUT", "Content-Type")
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "GET, PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "600"}
    ], ""} : Http.Reply}

# LAW (Fetch CORS): a method outside the allow-list is a failed preflight
law cors_preflight_method_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", "DELETE", "")
    == Http.Reply{400, [], ""} : Http.Reply}

# LAW (Fetch CORS): a simple response keeps its body and gains CORS headers
law cors_simple_reflects:
  {Cors.cors.simple(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Expose-Headers", "X-Trace"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"}
    ], "ok"} : Http.Reply}

# LAW (Fetch CORS): `*` without credentials is the only ACAO header
law cors_simple_star:
  {Cors.cors.simple(Cors.Cfg{["*"], ["GET"], [], False{}, "", []},
      "https://app.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [Http.H{"Access-Control-Allow-Origin", "*"}], "ok"}
    : Http.Reply}

# LAW (Fetch CORS): a refused origin leaves the handler reply unchanged
law cors_simple_refused:
  {Cors.cors.simple(Cors.Cfg{["https://ok.example"], [], [], False{}, "", []},
      "https://no.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [], "ok"} : Http.Reply}

# LAW (Fetch CORS): OPTIONS plus Access-Control-Request-Method is a preflight
law cors_on_preflight:
  {Cors.cors.on(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      Http.Request{"OPTIONS", "/", [
        Http.H{"Origin", "https://app.example"},
        Http.H{"Access-Control-Request-Method", "PUT"},
        Http.H{"Access-Control-Request-Headers", "Content-Type"}
      ], ""}, Http.Reply{200, [], "nope"})
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "GET, PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "600"}
    ], ""} : Http.Reply}

# LAW (Fetch CORS): Origin is the request header of that name
law cors_origin_header:
  {Cors.cors.origin("https://app.example")
    == Http.H{"Origin", "https://app.example"} : Http.Header}

# LAW (Fetch CORS): Access-Control-Request-Method names the method
law cors_request_method_header:
  {Cors.cors.request_method("PUT")
    == Http.H{"Access-Control-Request-Method", "PUT"} : Http.Header}

# LAW (Fetch CORS): Access-Control-Request-Headers names the headers
law cors_request_headers_header:
  {Cors.cors.request_headers("Content-Type")
    == Http.H{"Access-Control-Request-Headers", "Content-Type"} : Http.Header}

# --- thicker fence: more closed witnesses of the same RFCs ---

# LAW (RFC 3986 §3.2.3): http with no port is 80
law url_http_default_port:
  {Url.parse("http://example.com/a")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.4): a later `?` stays inside the query
law url_query_keeps_question:
  {Url.parse("http://example.com/a?x=1?y=2")
    == Url.Loc{"http", "example.com", 80, "/a?x=1?y=2"} : Url.Loc}

# LAW (RFC 3986 §3.5): a `?` inside the fragment is not a query
law url_fragment_hides_query:
  {Url.parse("http://example.com/a#b?c")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}

# LAW (RFC 3986 §3.2.1): the last `@` piece is the hostport
law url_userinfo_last_at:
  {Url.parse("http://a@b@example.com/z")
    == Url.Loc{"http", "example.com", 80, "/z"} : Url.Loc}

# LAW (RFC 3986 §3.3): a trailing slash is part of the path
law url_trailing_slash:
  {Url.parse("http://example.com/a/")
    == Url.Loc{"http", "example.com", 80, "/a/"} : Url.Loc}

# LAW (RFC 3986 §3.2.3): a non-numeric port falls back to the scheme default
law url_bad_port_uses_default:
  {Url.parse("http://example.com:abc/x")
    == Url.Loc{"http", "example.com", 80, "/x"} : Url.Loc}

# LAW (RFC 9110 §8.6): a non-empty request body is framed by Content-Length
law post_writes_content_length:
  {Http.request("POST", "h", "/a", [], "hi")
    == "POST /a HTTP/1.1\r\n"
      ++ "Host: h\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ "Content-Length: 2\r\n"
      ++ "\r\n"
      ++ "hi"
    : String}

# LAW (RFC 9110 §8.6): an empty GET omits Content-Length
law get_omits_content_length:
  {Http.get_req("h", "/", [])
    == "GET / HTTP/1.1\r\n"
      ++ "Host: h\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ "\r\n"
    : String}

# LAW (RFC 9110 §15.3.2): 201 Created
law reason_201:
  {Http.reason(201) == "Created" : String}

# LAW (RFC 9110 §15.3.5): 204 No Content
law reason_204:
  {Http.reason(204) == "No Content" : String}

# LAW (RFC 9110 §15.5.6): 405 Method Not Allowed
law reason_405:
  {Http.reason(405) == "Method Not Allowed" : String}

# LAW (RFC 9110 §15): a status we do not name has an empty reason-phrase
law reason_unknown_empty:
  {Http.reason(418) == "" : String}

# LAW (RFC 9110 §15.3.5): a 204 response is written with an empty body
law respond_204_drops_body:
  {Http.respond.of(Http.Reply{204, [], "nope"}) == Http.respond(204, [], "")
    : String}

# LAW (RFC 9110 §15.4.5): a 304 response is written with an empty body
law respond_304_drops_body:
  {Http.respond.of(Http.Reply{304, [], "nope"}) == Http.respond(304, [], "")
    : String}

# LAW (RFC 9110 §15.3.1): a 200 response keeps its body
law respond_200_keeps_body:
  {Http.respond.of(Http.Reply{200, [], "ok"}) == Http.respond(200, [], "ok")
    : String}

# LAW (RFC 9110 §9.2.1): HEAD is safe
law method_safe_head:
  {Http.method.safe("HEAD") == True{} : Bool}

# LAW (RFC 9110 §9.2.1): OPTIONS is safe
law method_safe_options:
  {Http.method.safe("OPTIONS") == True{} : Bool}

# LAW (RFC 9110 §9.2.1): PUT is not safe
law method_safe_put:
  {Http.method.safe("PUT") == False{} : Bool}

# LAW (RFC 9110 §9.2.1): DELETE is not safe
law method_safe_delete:
  {Http.method.safe("DELETE") == False{} : Bool}

# LAW (RFC 9110 §9.2.2): GET is idempotent
law method_idempotent_get:
  {Http.method.idempotent("GET") == True{} : Bool}

# LAW (RFC 9110 §9.2.2): HEAD is idempotent
law method_idempotent_head:
  {Http.method.idempotent("HEAD") == True{} : Bool}

# LAW (RFC 9110 §9.2.2): PATCH is not one of the idempotent methods we name
law method_idempotent_patch:
  {Http.method.idempotent("PATCH") == False{} : Bool}

# LAW (RFC 9110 §5.1): field lookup folds the name and keeps the value
law headers_find_ignores_case:
  {Http.headers.find([Http.H{"hOsT", "Ex.COM"}], "host") == "Ex.COM" : String}

# LAW (RFC 9110 §5.1): a missing field looks up as empty
law headers_find_missing:
  {Http.headers.find([], "host") == "" : String}

# LAW (RFC 9110 §5.2): the first field of a repeated name is the one found
law headers_find_first:
  {Http.headers.find([Http.H{"Host", "a"}, Http.H{"Host", "b"}], "host")
    == "a" : String}

# LAW (RFC 9110 §5.1): the wire spelling of a field name is kept
law ask_keeps_field_name_spelling:
  {Http.ask("GET / HTTP/1.1\r\nhOsT: Ex.COM\r\n\r\n")
    == Http.Request{"GET", "/", [Http.H{"hOsT", "Ex.COM"}], ""} : Http.Request}

# LAW (RFC 9112 §6.3): identical Content-Length values are that one length
law parse_equal_content_lengths:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 5\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Reply{200, [Http.H{"Content-Length", "5"},
      Http.H{"Content-Length", "5"}], "hello"} : Http.Reply}

# LAW (RFC 9112 §6.3): a request with both framings is bad
law ask_rejects_cl_and_te:
  {Http.ask("POST / HTTP/1.1\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n")
    == Http.Bad{"Content-Length and Transfer-Encoding conflict"} : Http.Request}

# LAW (RFC 9112 §6.3): a response whose Content-Length values differ is torn
law parse_rejects_disagreeing_cl:
  {Http.parse("HTTP/1.1 200 OK\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\nab")
    == Http.Torn{"Content-Length values disagree"} : Http.Reply}

# LAW (RFC 9112 §6.3): identical request Content-Length values frame one body
law ask_equal_content_lengths:
  {Http.ask("POST / HTTP/1.1\r\nContent-Length: 5\r\nContent-Length: 5\r\n\r\nhello!!")
    == Http.Request{"POST", "/", [Http.H{"Content-Length", "5"},
      Http.H{"Content-Length", "5"}], "hello"} : Http.Request}

# LAW (RFC 9112 §7.1): chunked is recognized in any case
law parse_chunked_ignores_case:
  {Http.parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: CHUNKED\r\n\r\n1\r\nZ\r\n0\r\n\r\n")
    == Http.Reply{200, [Http.H{"Transfer-Encoding", "CHUNKED"}], "Z"}
    : Http.Reply}

# LAW (RFC 9112 §7.1): a chunk-ext after `;` does not change the decoded body
law dechunk_ignores_extension:
  {Http.dechunk("5;ext=1\r\nhello\r\n0\r\n\r\n") == "hello" : String}

# LAW (RFC 9112 §7.1): the chunk of size 0 ends the body; a trailer is not data
law dechunk_stops_at_zero:
  {Http.dechunk("5\r\nhello\r\n0\r\nIgnored: 1\r\n\r\n") == "hello" : String}

# LAW (RFC 9112 §7.1): a body that is only the last chunk is empty
law dechunk_only_last:
  {Http.dechunk("0\r\n\r\n") == "" : String}

# LAW (RFC 9112 §7.1): chunk-size is hexadecimal, and an extension is skipped
law hexlen_extension_and_case:
  {Http.hexlen("5;ext=1") == 5n : Nat}

# LAW (RFC 9112 §7.1): `a` and `A` are the same chunk-size digit
law hexlen_alpha:
  {Http.hexlen("a") == Http.hexlen("A") : Nat}

# LAW (RFC 9112 §6.3): Content-Length is a decimal, not a prefix of junk
law digits_read_decimal:
  {Http.digits.read("12") == Some{12n} : Maybe<&2, Nat>}

# LAW (RFC 9112 §6.3): a Content-Length that is not all digits is absent
law digits_read_rejects_junk:
  {Http.digits.read("12a") == None{} : Maybe<&2, Nat>}

# LAW (RFC 9112 §3.2.4): OPTIONS asterisk-form names the whole server
law ask_options_asterisk:
  {Http.ask("OPTIONS * HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Request{"OPTIONS", "*", [Http.H{"Host", "h"}], ""} : Http.Request}

# LAW (RFC 9112 §3.2.4): asterisk-form is not a GET target
law ask_get_asterisk_rejected:
  {Http.ask("GET * HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}

# LAW (RFC 9112 §3.2.2): absolute-form is not accepted as origin-form
law ask_rejects_absolute_form:
  {Http.ask("GET http://example.com/a HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}

# LAW (RFC 4648 §10 / RFC 7617 §2): user:pass is the Basic credential alphabet
law b64_user_pass:
  {B64.b64.encode("user:pass") == "dXNlcjpwYXNz" : String}

# LAW (RFC 6750 §2.1): a newline is not a bearer token character
law token_ok_newline:
  {Http.token.ok("a\nb") == False{} : Bool}

# LAW (RFC 6265 §4.1.1): SameSite=STRICT is canonical Strict
law cookie_samesite_strict:
  {Cookie.cookie.parse("a=b; SameSite=STRICT")
    == Some{Cookie.Cookie{"a", "b", "", "", "", "", False{}, False{},
      "Strict", True{}}} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §4.1.1): SameSite=none is canonical None
law cookie_samesite_none:
  {Cookie.cookie.parse("a=b; SameSite=none")
    == Some{Cookie.Cookie{"a", "b", "", "", "", "", False{}, False{},
      "None", True{}}} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §4.1.1): an unknown SameSite attribute is dropped
law cookie_samesite_unknown:
  {Cookie.cookie.parse("a=b; SameSite=weird")
    == Some{Cookie.cookie.new("a", "b")} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §5.2.2): a Max-Age that is not digits is ignored
law cookie_max_age_ignores_junk:
  {Cookie.cookie.parse("a=b; Max-Age=nope")
    == Some{Cookie.cookie.new("a", "b")} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §5.2.3): a Domain attribute is stored lowercase
law cookie_domain_lowercased:
  {Cookie.cookie.parse("a=b; Domain=Example.COM")
    == Some{Cookie.Cookie{"a", "b", "", "", "example.com", "", False{},
      False{}, "", False{}}} : Maybe<&2, Cookie.Cookie>}

# LAW (RFC 6265 §5.1.4): identical paths match
law cookie_path_identical:
  {Cookie.cookie.path_ok("/app", "/app") == True{} : Bool}

# LAW (RFC 6265 §5.1.4): default-path `/` matches a longer request path
law cookie_path_root:
  {Cookie.cookie.path_ok("/a", "/") == True{} : Bool}

# LAW (RFC 6265 §5.1.4): a cookie-path the request does not extend fails
law cookie_path_longer_cookie:
  {Cookie.cookie.path_ok("/app", "/app/") == False{} : Bool}

# LAW (RFC 6265 §5.1.4): a cookie-path that already ends in `/` is a prefix
law cookie_path_slash_prefix:
  {Cookie.cookie.path_ok("/app/x", "/app/") == True{} : Bool}

# LAW (RFC 6265 §5.1.4): one slash is not enough for a directory default-path
law cookie_default_path_one_slash:
  {Cookie.cookie.default_path("/") == "/" : String}

# LAW (RFC 6265 §5.1.3): an IPv4 literal is recognized, a name is not
law cookie_ipv4_literal:
  {Cookie.cookie.ipv4("192.0.2.1") == True{} : Bool}

# LAW (RFC 6265 §5.1.3): a registered name is not an IPv4 address
law cookie_ipv4_name:
  {Cookie.cookie.ipv4("example.com") == False{} : Bool}

# LAW (RFC 6265 §5.4): a host-only cookie is sent on its host and default-path
law cookie_send_host_only:
  {Cookie.cookie.send("example.com", "/a/x", False{},
      Cookie.cookie.receive("Example.COM", "/a/b", Cookie.cookie.new("a", "b")))
    == True{} : Bool}

# LAW (RFC 6265 §5.4): a host-only cookie is not sent to another host
law cookie_send_other_host:
  {Cookie.cookie.send("other.com", "/", False{},
      Cookie.cookie.receive("example.com", "/", Cookie.cookie.new("a", "b")))
    == False{} : Bool}

# LAW (RFC 6265 §5.4): a cookie with no Domain does not match a different host
law cookie_send_unset_domain:
  {Cookie.cookie.send("h", "/", False{}, Cookie.cookie.new("a", "b"))
    == False{} : Bool}

# LAW (RFC 6265 §5.4): a cookie that is not Secure is sent on cleartext
law cookie_insecure_on_tcp:
  {Cookie.cookie.send.secure(False{}, False{}) == True{} : Bool}

# LAW (RFC 6265 §5.4): Max-Age 1 is alive at age 0 and stale at age 1
law cookie_max_age_one:
  {Bool.and(Cookie.cookie.alive("1", 0n),
      Bool.not(Cookie.cookie.alive("1", 1n))) == True{} : Bool}

# LAW (RFC 9111 §5.2): an unrecognized directive is ignored
law cache_ignores_s_maxage:
  {Cache.cache.parse("s-maxage=9, max-age=3")
    == Cache.Cc{False{}, False{}, False{}, False{}, "3", ""} : Cache.Cc}

# LAW (RFC 9111 §5.2.1.1): a non-digit max-age is not recorded
law cache_max_age_ignores_junk:
  {Cache.cache.parse("max-age=nope")
    == Cache.Cc{False{}, False{}, False{}, False{}, "", ""} : Cache.Cc}

# LAW (RFC 9111 §5.2.2.2): no-cache alone is recorded and not fresh
law cache_no_cache_alone:
  {Cache.cache.parse("no-cache")
    == Cache.Cc{False{}, True{}, False{}, False{}, "", ""} : Cache.Cc}

# LAW (RFC 9111 §5.2.2.6): private alone is recorded
law cache_private_alone:
  {Cache.cache.parse("private")
    == Cache.Cc{False{}, False{}, False{}, True{}, "", ""} : Cache.Cc}

# LAW (RFC 9111 §4.2.1): max-age=1 is fresh at 0 and stale at 1
law fresh_max_age_one:
  {Bool.and(Cache.cache.fresh(Cache.cache.parse("max-age=1"), 0n),
      Bool.not(Cache.cache.fresh(Cache.cache.parse("max-age=1"), 1n)))
    == True{} : Bool}

# LAW (Fetch CORS): requested header names are matched case-insensitively
law cors_preflight_header_case:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://app.example", "PUT", "content-type")
    == Http.Reply{200, [
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "10"}
    ], ""} : Http.Reply}

# LAW (Fetch CORS): a preflight whose origin is not allowed is 400
law cors_preflight_origin_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://no.example", "PUT", "")
    == Http.Reply{400, [], ""} : Http.Reply}

# LAW (Fetch CORS): a requested header outside the allow-list fails preflight
law cors_preflight_header_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://app.example", "PUT", "X-Nope")
    == Http.Reply{400, [], ""} : Http.Reply}

# LAW (Fetch CORS): credentials with an explicit origin still reflect it
law cors_credentials_explicit_origin:
  {Cors.cors.acao(["https://app.example"], True{}, "https://app.example")
    == "https://app.example" : String}

# LAW (Fetch CORS): a GET with no Access-Control-Request-Method is not a preflight
law cors_get_is_not_preflight:
  {Cors.cors.is_preflight(Http.Request{"GET", "/",
      [Http.H{"Origin", "https://a"}], ""}) == False{} : Bool}

# LAW: a JSON string is a text body of its compact encoding. The HTTP types
# stay text (the body is not a JSON value).
law json_string_is_text_body:
  {Json.json.body(Ezjson.str("hi")) == Body.body.text("\"hi\"") : Body.Body}

# LAW: a JSON string parses back to that string
law json_parse_string:
  {Json.json.as_str(Json.json.parse("\"hi\"")) == Some{"hi"} : Maybe<&2, String>}

# LAW: text that is not JSON is none
law json_parse_rejects:
  {Json.json.as_str(Json.json.parse("nope")) == None{} : Maybe<&2, String>}

# LAW (Fetch CORS): `*` without credentials is ACAO on a successful preflight
law cors_preflight_star:
  {Cors.cors.preflight(Cors.Cfg{["*"], ["GET"], [], False{}, "0", []},
      "https://a", "GET", "")
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Origin", "*"},
      Http.H{"Access-Control-Allow-Methods", "GET"},
      Http.H{"Access-Control-Allow-Headers", ""},
      Http.H{"Access-Control-Max-Age", "0"}
    ], ""} : Http.Reply}

# --- the server's decisions (SPEC.md HTTP-SRV) ---

# LAW: a request that does not parse is answered 400 with its reason, and
# the handler is not called
# HTTP-SRV-1
law step_bad:
  for why: String
  {Step.step.of(Http.Bad{why}) == Step.Answer{Http.Reply{400, [], why}}
    : Step.Step}

# LAW: a request that parses goes to the handler exactly as it was parsed
# HTTP-SRV-2
law step_call:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for body: String
  {Step.step.of(Http.Request{method, target, hs, body})
    == Step.Call{Http.Request{method, target, hs, body}} : Step.Step}

# LAW (RFC 9110 §9.3.2): a reply to HEAD loses its body and keeps the rest
# HTTP-SRV-3
law shape_head:
  for status: U32
  for hs: List<&2, Http.Header>
  for body: String
  {Http.reply.for("HEAD", Http.Reply{status, hs, body})
    == Http.Reply{status, hs, ""} : Http.Reply}

# LAW: a reply to any method other than HEAD is left as it is
# HTTP-SRV-3
law shape_other:
  for method: String
  for e: {False{} == String.eq(method, "HEAD") : Bool}
  for reply: Http.Reply
  {Http.reply.for(method, reply) == reply : Http.Reply}

# LAW (RFC 9110 §15.3.5): a 204 is written with no body
# HTTP-SRV-3
law respond_204:
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{204, hs, body}) == Http.respond(204, hs, "")
    : String}

# LAW (RFC 9110 §15.4.5): a 304 is written with no body
# HTTP-SRV-3
law respond_304:
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{304, hs, body}) == Http.respond(304, hs, "")
    : String}

# LAW: any other status is written with its headers and body as they are
# HTTP-SRV-3
law respond_other:
  for +status: U32
  for e: {False{} == Http.status.nocontent(status) : Bool}
  for hs: List<&2, Http.Header>
  for body: String
  {Http.respond.of(Http.Reply{status, hs, body})
    == Http.respond(status, hs, body) : String}

# LAW: a failed accept or recv loses the connection with the line
# `ezhttp: <phase>: <why>`
# HTTP-SRV-4
law lost_failed:
  for -A: Type
  for phase: String
  for code: U32
  for why: String
  {Step.step.got(A, phase, Fail{(code, why)})
    == Step.Lost{"ezhttp: " ++ phase ++ ": " ++ why} : Step.Got<A>}

# LAW: an accept or recv that succeeds hands on its value unchanged
# HTTP-SRV-4
law lost_kept:
  for -A: Type
  for phase: String
  for value: A
  {Step.step.got(A, phase, Done{value}) == Step.Kept{value} : Step.Got<A>}

# LAW: a failed send loses the connection with the line `ezhttp: write: <why>`
# HTTP-SRV-4
law lost_send:
  for code: U32
  for why: String
  for left: List<&2, U32>
  {Step.step.sent(Fail{((code, why), left)})
    == Step.Lost{"ezhttp: write: " ++ why} : Step.Got<Unit>}

# LAW: a send that succeeds keeps the connection
# HTTP-SRV-4
law lost_sent:
  for done: Unit
  {Step.step.sent(Done{done}) == Step.Kept{done} : Step.Got<Unit>}

# the reason-phrases SPEC.md HTTP-SRV-5 lists, as it words them
def phrases() -> List<&2, Http.Phrase>:
  [Http.P{200, "OK"}, Http.P{201, "Created"}, Http.P{202, "Accepted"},
    Http.P{204, "No Content"}, Http.P{301, "Moved Permanently"},
    Http.P{302, "Found"}, Http.P{303, "See Other"},
    Http.P{304, "Not Modified"}, Http.P{307, "Temporary Redirect"},
    Http.P{308, "Permanent Redirect"}, Http.P{400, "Bad Request"},
    Http.P{401, "Unauthorized"}, Http.P{403, "Forbidden"},
    Http.P{404, "Not Found"}, Http.P{405, "Method Not Allowed"},
    Http.P{409, "Conflict"}, Http.P{410, "Gone"},
    Http.P{413, "Content Too Large"}, Http.P{415, "Unsupported Media Type"},
    Http.P{422, "Unprocessable Content"}, Http.P{429, "Too Many Requests"},
    Http.P{500, "Internal Server Error"}, Http.P{501, "Not Implemented"},
    Http.P{502, "Bad Gateway"}, Http.P{503, "Service Unavailable"},
    Http.P{504, "Gateway Timeout"}]

# LAW: every status's reason-phrase is the one HTTP-SRV-5 lists for it, and
# empty for a status it does not list
# HTTP-SRV-5
law reason_phrases:
  for +code: U32
  {Http.reason(code) == Http.reason.in(phrases(), code) : String}

# LAW: a list with no entries gives every status the empty phrase
# HTTP-SRV-5
law reason_in_nil:
  for +code: U32
  {Http.reason.in([], code) == "" : String}

# LAW: a list gives a status its first entry's phrase when that entry is for
# that status
# HTTP-SRV-5
law reason_in_hit:
  for +code: U32
  for c: U32
  for text: String
  for t: List<&2, Http.Phrase>
  for e: {True{} == U32.is_eq(code, c) : Bool}
  {Http.reason.in(Http.P{c, text} <> t, code) == text : String}

# LAW: and the rest's phrase when it is for another status
# HTTP-SRV-5
law reason_in_miss:
  for +code: U32
  for c: U32
  for text: String
  for t: List<&2, Http.Phrase>
  for e: {False{} == U32.is_eq(code, c) : Bool}
  {Http.reason.in(Http.P{c, text} <> t, code) == Http.reason.in(t, code)
    : String}

# --- percent-encoding (SPEC.md HTTP-URL) ---

# LAW: the empty string is written as the empty string, in both forms
# HTTP-URL-1
law quote_nil:
  for +slash: Bool
  {Pct.quote(slash, "") == "" : String}

# LAW: a string is written one character at a time, the first character's
# writing followed by the rest's
# HTTP-URL-1
law quote_cons:
  for +slash: Bool
  for +c: U32
  for t: String
  {Pct.quote(slash, SCon{Chr{c}, t})
    == Pct.one(slash, c, Pct.quote(slash, t)) : String}

# LAW (RFC 3986 §2.3): an unreserved character is written as itself
# HTTP-URL-1
law one_unreserved:
  for slash: Bool
  for +c: U32
  for e: {True{} == Pct.unreserved(c) : Bool}
  for rest: String
  {Pct.one(slash, c, rest) == SCon{Chr{c}, rest} : String}

# LAW (RFC 3986 §2.1): a character the form does not keep is written as the
# %XX triples of its UTF-8 bytes
# HTTP-URL-2
law one_escaped:
  for slash: Bool
  for +c: U32
  for e: {False{} == Pct.safe(slash, c) : Bool}
  for rest: String
  {Pct.one(slash, c, rest) == Pct.pct(Pct.utf8(c), rest) : String}

# LAW: no bytes write nothing
# HTTP-URL-2
law pct_nil:
  for rest: String
  {Pct.pct([], rest) == rest : String}

# LAW (RFC 3986 §2.1): a byte is written as "%", its high nibble, its low
# nibble, before the bytes after it
# HTTP-URL-2
law pct_cons:
  for +b: U32
  for bs: List<&2, U32>
  for rest: String
  {Pct.pct(b <> bs, rest)
    == SCon{'%', SCon{Pct.hex(U32.shrn(b, 4n)),
      SCon{Pct.hex(U32.and(b, 15)), Pct.pct(bs, rest)}}} : String}

# LAW: a nibble below 10 is the digit '0' + n
# HTTP-URL-2
law hex_digit:
  for +n: U32
  for e: {True{} == U32.is_lt(n, 10) : Bool}
  {Pct.hex(n) == Chr{U32.add(48, n)} : Char}

# LAW (RFC 3986 §2.1, upper case): a nibble of 10 or more is the letter
# 'A' + (n - 10), that is code 55 + n
# HTTP-URL-2
law hex_letter:
  for +n: U32
  for e: {False{} == U32.is_lt(n, 10) : Bool}
  {Pct.hex(n) == Chr{U32.add(55, n)} : Char}

# LAW (RFC 3629 §3): U+0000 to U+007F is one byte, 0xxxxxxx
# HTTP-URL-2
law utf8_one:
  for +c: U32
  for e: {True{} == U32.is_lt(c, 128) : Bool}
  {Pct.utf8(c) == [c] : List<&2, U32>}

# LAW (RFC 3629 §3): U+0080 to U+07FF is two bytes, 110xxxxx 10xxxxxx
# HTTP-URL-2
law utf8_two:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {True{} == U32.is_lt(c, 2048) : Bool}
  {Pct.utf8(c) == [U32.or(192, U32.shrn(c, 6n)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

# LAW (RFC 3629 §3): U+0800 to U+FFFF is three bytes,
# 1110xxxx 10xxxxxx 10xxxxxx
# HTTP-URL-2
law utf8_three:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {False{} == U32.is_lt(c, 2048) : Bool}
  for e3: {True{} == U32.is_lt(c, 65536) : Bool}
  {Pct.utf8(c) == [U32.or(224, U32.shrn(c, 12n)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

# LAW (RFC 3629 §3): U+10000 to U+10FFFF is four bytes,
# 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
# HTTP-URL-2
law utf8_four:
  for +c: U32
  for e1: {False{} == U32.is_lt(c, 128) : Bool}
  for e2: {False{} == U32.is_lt(c, 2048) : Bool}
  for e3: {False{} == U32.is_lt(c, 65536) : Bool}
  {Pct.utf8(c) == [U32.or(240, U32.shrn(c, 18n)),
    U32.or(128, U32.and(U32.shrn(c, 12n), 63)),
    U32.or(128, U32.and(U32.shrn(c, 6n), 63)),
    U32.or(128, U32.and(c, 63))] : List<&2, U32>}

# LAW: the path form writes "/" as itself
# HTTP-URL-3
law path_keeps_slash:
  for rest: String
  {Pct.one(True{}, 47, rest) == SCon{'/', rest} : String}

# LAW: the component form writes "/" as %2F
# HTTP-URL-3
law component_escapes_slash:
  for rest: String
  {Pct.one(False{}, 47, rest) == SCon{'%', SCon{'2', SCon{'F', rest}}}
    : String}

# LAW: on every character but "/" the component form writes what the path
# form writes
# HTTP-URL-3
law component_is_path_elsewhere:
  for +c: U32
  for e: {False{} == U32.is_eq(c, 47) : Bool}
  for rest: String
  {Pct.one(False{}, c, rest) == Pct.one(True{}, c, rest) : String}

# an upper-case hex digit: 0-9 or A-F
def hexdig(ch: Char) -> Bool:
  match ch:
    case Chr{+code}:
      Bool.or(Bool.and(U32.is_le(48, code), U32.is_le(code, 57)),
        Bool.and(U32.is_le(65, code), U32.is_le(code, 70)))

# whether character cp may come next, `need` hex digits still owed to a "%":
# with none owed, a kept character or a "%"; otherwise a hex digit
def framed.ok(slash: Bool, +cp: U32, need: Nat) -> Bool:
  match need:
    case 0n:
      Bool.or(Pct.safe(slash, cp), U32.is_eq(cp, 37))
    case 1n+p:
      hexdig(Chr{cp})

# hex digits owed after character cp: two after a "%", one fewer after a digit
def framed.next(slash: Bool, +cp: U32, need: Nat) -> Nat:
  match need:
    case 0n:
      Bool.pick(Nat, Pct.safe(slash, cp), 0n,
        Bool.pick(Nat, U32.is_eq(cp, 37), 2n, 0n))
    case 1n+p:
      p

# no hex digit is still owed at the end
def framed.end(need: Nat) -> Bool:
  match need:
    case 0n:
      True{}
    case 1n+p:
      False{}

# the HTTP-URL-4 frame read left to right: kept characters, and "%" followed
# by exactly two hex digits
def framed(+slash: Bool, str: String, +need: Nat) -> Bool:
  match str:
    case SNil{}:
      framed.end(need)
    case SCon{Chr{+cp}, tail}:
      Bool.and(framed.ok(slash, cp, need),
        framed(slash, tail, framed.next(slash, cp, need)))

# both nibbles of every byte are written as hex digits
def hexes(bs: List<&2, U32>) -> Bool:
  match bs:
    case []:
      True{}
    case +byte <> tail:
      Bool.and(hexdig(Pct.hex(U32.shrn(byte, 4n))),
        Bool.and(hexdig(Pct.hex(U32.and(byte, 15))), hexes(tail)))

# LAW (partial): a kept character stays in the frame
# HTTP-URL-4
law frame_kept:
  for +slash: Bool
  for +c: U32
  for +e: {True{} == Pct.safe(slash, c) : Bool}
  for rest: String
  {framed(slash, Pct.one(slash, c, rest), 0n) == framed(slash, rest, 0n)
    : Bool}

# LAW (partial): %XX triples stay in the frame when their nibbles are hex
# digits
# HTTP-URL-4
law frame_bytes:
  for +slash: Bool
  for bs: List<&2, U32>
  for +e: {hexes(bs) == True{} : Bool}
  for +rest: String
  {framed(slash, Pct.pct(bs, rest), 0n) == framed(slash, rest, 0n) : Bool}

# every character the form does not keep has UTF-8 bytes whose nibbles are
# written as hex digits
def nibbles(+slash: Bool, str: String) -> Bool:
  match str:
    case SNil{}:
      True{}
    case SCon{Chr{+cp}, tail}:
      Bool.and(Bool.or(Pct.safe(slash, cp), hexes(Pct.utf8(cp))),
        nibbles(slash, tail))

# LAW (partial): the whole output is in the frame, given that every escaped
# character's nibbles are written as hex digits
# HTTP-URL-4
law frame_quote:
  for +slash: Bool
  for +str: String
  for +e: {nibbles(slash, str) == True{} : Bool}
  {framed(slash, Pct.quote(slash, str), 0n) == True{} : Bool}

# --- the client's timeout (SPEC.md HTTP-CLI) ---

# LAW: a timed spec carries exactly the timeout it was given: the effect reads
# back the same number of milliseconds
# HTTP-CLI-1
law spec_timed_ms:
  for +secure: Bool
  for ms: U32
  for +host: String
  for +port: U32
  for +req: String
  {Spec.wire.ms(Spec.wire.spec.timed(secure, ms, host, port, req)) == ms
    : U32}

# LAW: the spec every other client call sends carries no timeout, and the
# effect reads 60000 ms from it
# HTTP-CLI-1
law spec_plain_ms:
  for secure: Bool
  for host: String
  for port: U32
  for req: String
  {Spec.wire.ms(Spec.wire.spec(secure, host, port, req)) == 60000 : U32}

# LAW: a timed spec is its first line (scheme, a space, the timeout), then
# host, port and request on the lines the untimed spec puts them
# HTTP-CLI-2
law spec_timed_lines:
  for secure: Bool
  for ms: U32
  for host: String
  for port: U32
  for req: String
  {Spec.wire.spec.timed(secure, ms, host, port, req)
    == (Spec.wire.scheme(secure) ++ " " ++ Spec.wire.ms.text(ms)) ++ "\n"
      ++ host ++ "\n" ++ U32.show(port) ++ "\n" ++ req : String}

# LAW: the untimed spec is the scheme alone on its first line, then host,
# port and request
# HTTP-CLI-2
law spec_plain_lines:
  for secure: Bool
  for host: String
  for port: U32
  for req: String
  {Spec.wire.spec(secure, host, port, req)
    == Spec.wire.scheme(secure) ++ "\n" ++ host ++ "\n" ++ U32.show(port)
      ++ "\n" ++ req : String}

# LAW: a failed exchange with status 28 is reported as `timed out: <why>`
# HTTP-CLI-3
law why_late:
  for why: String
  {Spec.wire.why(Some{28}, why) == "timed out: " ++ why : String}

# LAW: a failed exchange with any other status keeps its reason unchanged
# HTTP-CLI-3
law why_other:
  for +n: U32
  for e: {False{} == U32.is_eq(n, 28) : Bool}
  for why: String
  {Spec.wire.why(Some{n}, why) == why : String}

# LAW: a failed exchange with no status keeps its reason unchanged
# HTTP-CLI-3
law why_none:
  for why: String
  {Spec.wire.why(None{}, why) == why : String}

# LAW: the reason reported for status 28 is one timed_out recognizes
# HTTP-CLI-3
law why_late_timed_out:
  for why: String
  {Spec.wire.timed_out(Spec.wire.why(Some{28}, why)) == True{} : Bool}

# --- the client's requests (SPEC.md HTTP-CLI-4) ---

# LAW (RFC 9110 §7.2): on port 80 an http request's Host is the host alone
# HTTP-CLI-4
law host_http_default:
  for host: String
  {Http.authority(False{}, host, 80) == host : String}

# LAW (RFC 9110 §7.2): on port 443 an https request's Host is the host alone
# HTTP-CLI-4
law host_https_default:
  for host: String
  {Http.authority(True{}, host, 443) == host : String}

# LAW (RFC 9110 §7.2): on any other port an http request's Host is
# `host:port`
# HTTP-CLI-4
law host_http_other:
  for host: String
  for +port: U32
  for e: {False{} == U32.is_eq(port, 80) : Bool}
  {Http.authority(False{}, host, port) == host ++ ":" ++ U32.show(port)
    : String}

# LAW (RFC 9110 §7.2): on any other port an https request's Host is
# `host:port`
# HTTP-CLI-4
law host_https_other:
  for host: String
  for +port: U32
  for e: {False{} == U32.is_eq(port, 443) : Bool}
  {Http.authority(True{}, host, port) == host ++ ":" ++ U32.show(port)
    : String}

# LAW (RFC 9110 §7.2, RFC 9112 §3): the request a client writes for a host
# and port is its request line, the header fields request.fields gives for
# that Host value, a blank line and the body
# HTTP-CLI-4
law request_at:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.request.at(method, secure, host, port, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(
        Http.request.fields(Http.authority(secure, host, port), hs, body))
      ++ "\r\n"
      ++ body
    : String}

# LAW: a URL that does not parse sends nothing and keeps its reason
# HTTP-CLI-4
law exchange_bad:
  for method: String
  for why: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange(method, Url.Bad{why}, hs, body) == Spec.NoUrl{why}
    : Spec.Exchange}

# LAW: a URL that parses is sent to its host and port, over TLS exactly when
# its scheme is https, with the method it was given and the request
# request.at writes for them
# HTTP-CLI-4
# HTTP-CLI-7
law exchange_loc:
  for method: String
  for +scheme: String
  for +host: String
  for +port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange(method, Url.Loc{scheme, host, port, path}, hs, body)
    == Spec.Exchange{String.eq(scheme, "https"), host, port, method,
      Http.request.at(method, String.eq(scheme, "https"), host, port, path, hs,
        body)} : Spec.Exchange}

# LAW: the method the wire layer reads the answer by is the method the
# exchange was built for, for every method and every URL that parses
# HTTP-CLI-7
law exchange_method:
  for method: String
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for body: String
  {Spec.wire.exchange.method(
    Spec.wire.exchange(method, Url.Loc{scheme, host, port, path}, hs, body))
    == Some{method} : Maybe<&2, String>}

# LAW (RFC 9112 §3): for every method, the request a client writes opens with
# that method, the path and the protocol version on its request line
# HTTP-CLI-7
law request_line:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.request.at(method, secure, host, port, path, hs,
    body), method ++ " " ++ path ++ " HTTP/1.1\r\n") == True{} : Bool}

# --- the request's header fields (SPEC.md HTTP-CLI-8) ---

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `host` is Host
# HTTP-CLI-8
law field_host:
  for +name: String
  for e: {"host" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FHost{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `user-agent` is
# User-Agent
# HTTP-CLI-8
law field_agent:
  for +name: String
  for e: {"user-agent" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FAgent{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `accept` is
# Accept
# HTTP-CLI-8
law field_accept:
  for +name: String
  for e: {"accept" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FAccept{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is `connection` is
# Connection
# HTTP-CLI-8
law field_conn:
  for +name: String
  for e: {"connection" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FConn{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is
# `content-length` is Content-Length
# HTTP-CLI-8
law field_clen:
  for +name: String
  for e: {"content-length" == String.to_lower(name) : String}
  {Http.field.name(name) == Http.FClen{} : Http.Field}

# LAW (RFC 9110 §5.1): a field name whose lower-case form is none of the five
# is another field
# HTTP-CLI-8
law field_other:
  for +name: String
  for eh: {False{} == String.eq(String.to_lower(name), "host") : Bool}
  for ea: {False{} == String.eq(String.to_lower(name), "user-agent") : Bool}
  for ec: {False{} == String.eq(String.to_lower(name), "accept") : Bool}
  for en: {False{} == String.eq(String.to_lower(name), "connection") : Bool}
  for el: {False{} == String.eq(String.to_lower(name), "content-length")
    : Bool}
  {Http.field.name(name) == Http.FOther{} : Http.Field}

# LAW (RFC 9112 §3): the request is its request line, its header fields, a
# blank line and the body
# HTTP-CLI-8
law request_text:
  for +method: String
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {Http.request(method, host, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, body))
      ++ "\r\n"
      ++ body
    : String}

# LAW: a caller's Host fields replace the default: the request's Host fields
# are exactly the caller's, in order
# HTTP-CLI-8
law fields_host_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FHost{}, hs) == h <> t : List<&2, Http.Header>}
  {Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW (RFC 9110 §7.2): with no Host field from the caller, the request's Host
# fields are exactly the default one
# HTTP-CLI-8
law fields_host_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FHost{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FHost{}, Http.request.fields(host, hs, body))
    == [Http.H{"Host", host}] : List<&2, Http.Header>}

# LAW: a caller's User-Agent fields replace the default: the request's
# User-Agent fields are exactly the caller's, in order
# HTTP-CLI-8
law fields_agent_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FAgent{}, hs) == h <> t : List<&2, Http.Header>}
  {Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW: with no User-Agent field from the caller, the request's User-Agent
# fields are exactly `User-Agent: ezhttp`
# HTTP-CLI-8
law fields_agent_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FAgent{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FAgent{}, Http.request.fields(host, hs, body))
    == [Http.H{"User-Agent", "ezhttp"}] : List<&2, Http.Header>}

# LAW: a caller's Accept fields replace the default: the request's Accept
# fields are exactly the caller's, in order
# HTTP-CLI-8
law fields_accept_caller:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +h: Http.Header
  for +t: List<&2, Http.Header>
  for +e: {Http.fields.of(Http.FAccept{}, hs) == h <> t
    : List<&2, Http.Header>}
  {Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body))
    == h <> t : List<&2, Http.Header>}

# LAW: with no Accept field from the caller, the request's Accept fields are
# exactly `Accept: */*`
# HTTP-CLI-8
law fields_accept_dflt:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +e: {Http.fields.of(Http.FAccept{}, hs) == [] : List<&2, Http.Header>}
  {Http.fields.of(Http.FAccept{}, Http.request.fields(host, hs, body))
    == [Http.H{"Accept", "*/*"}] : List<&2, Http.Header>}

# LAW (RFC 9112 §9.6): whatever the caller gave, the request's Connection
# fields are exactly `Connection: close`
# HTTP-CLI-8
law fields_conn:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FConn{}, Http.request.fields(host, hs, body))
    == [Http.H{"Connection", "close"}] : List<&2, Http.Header>}

# LAW (RFC 9110 §8.6): whatever the caller gave, the request's Content-Length
# fields are exactly the one computed from the body
# HTTP-CLI-8
law fields_clen:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FClen{}, Http.request.fields(host, hs, body))
    == Http.clen.field(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
    : List<&2, Http.Header>}

# LAW: the caller's fields of every other name are sent unchanged and in
# order, and the request adds none of its own
# HTTP-CLI-8
law fields_other:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.fields.of(Http.FOther{}, Http.request.fields(host, hs, body))
    == Http.fields.of(Http.FOther{}, hs) : List<&2, Http.Header>}

# LAW (RFC 9110 §7.2, RFC 9112 §3, §9.6): a caller that names none of the
# five defaulted fields gets the request ezhttp has always written: Host,
# User-Agent, Accept, Connection: close, its own fields, Content-Length
# HTTP-CLI-8
law request_plain:
  for +method: String
  for +host: String
  for +path: String
  for +hs: List<&2, Http.Header>
  for +body: String
  for +eh: {Http.fields.of(Http.FHost{}, hs) == [] : List<&2, Http.Header>}
  for +ea: {Http.fields.of(Http.FAgent{}, hs) == [] : List<&2, Http.Header>}
  for +ec: {Http.fields.of(Http.FAccept{}, hs) == [] : List<&2, Http.Header>}
  for +eo: {Http.fields.of(Http.FOther{}, hs) == hs : List<&2, Http.Header>}
  {Http.request(method, host, path, hs, body)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ "Host: " ++ host ++ "\r\n"
      ++ "User-Agent: ezhttp\r\n"
      ++ "Accept: */*\r\n"
      ++ "Connection: close\r\n"
      ++ Http.headers.lines(hs)
      ++ Http.clen.line(Http.utf8.len(body), Nat.is_eq(Http.utf8.len(body), 0n))
      ++ "\r\n"
      ++ body
    : String}

# --- when a response is whole (SPEC.md HTTP-CLI-5) ---

# LAW: a text is read head by head for the request's method, at most as many
# heads as it has characters
# HTTP-CLI-5
law whole_go:
  for +method: String
  for +raw: String
  {Http.whole(method, raw)
    == Http.whole.go(String.length(raw), String.eq(method, "HEAD"),
      Http.divide(raw, "\r\n\r\n")) : Bool}

# LAW: a read with no heads left is not whole
# HTTP-CLI-5
law whole_fuel:
  for asked: Bool
  for c: Http.Cut
  {Http.whole.go(0n, asked, c) == False{} : Bool}

# LAW (RFC 9112 §2.1): a response whose header section has not ended is not
# whole
# HTTP-CLI-5
law whole_open:
  for f: Nat
  for asked: Bool
  {Http.whole.go(1n+f, asked, Http.NoCut{}) == False{} : Bool}

# LAW (RFC 9110 §15.2): after an interim (1xx) head, the response is whole
# exactly when the text after that head is
# HTTP-CLI-5
law whole_interim:
  for f: Nat
  for +asked: Bool
  for +before: String
  for +after: String
  for e: {True{} == Http.status.interim(Http.status.of(String.lines(before)))
    : Bool}
  {Http.whole.go(1n+f, asked, Http.Cut{before, after})
    == Http.whole.go(f, asked, Http.divide(after, "\r\n\r\n")) : Bool}

# LAW (RFC 9112 §6.3): once a final header section has ended, a response is
# whole exactly when its body is, under the framing its head and the
# request's method give
# HTTP-CLI-5
law whole_head:
  for f: Nat
  for +asked: Bool
  for +before: String
  for +after: String
  for e: {False{} == Http.status.interim(Http.status.of(String.lines(before)))
    : Bool}
  {Http.whole.go(1n+f, asked, Http.Cut{before, after})
    == Http.whole.of(Http.frame(Bool.or(asked,
      Http.status.bare(Http.status.of(String.lines(before)))),
      Http.head.go(String.lines(before), "transfer-encoding"),
      Http.head.values(String.lines(before), "content-length")), after)
    : Bool}

# LAW (RFC 9110 §15.2): a status is interim exactly when it is 100 to 199
# HTTP-CLI-5
# HTTP-CLI-9
law status_interim_some:
  for +n: U32
  {Http.status.interim(Some{n})
    == Bool.and(U32.is_le(100, n), U32.is_lt(n, 200)) : Bool}

# LAW: a status line that does not parse is not interim
# HTTP-CLI-5
# HTTP-CLI-9
law status_interim_none:
  for m: Maybe<&2, U32>
  for e: {None{} == m : Maybe<&2, U32>}
  {Http.status.interim(m) == False{} : Bool}

# LAW (RFC 9112 §4): a status line's code is its second word, as a number
# HTTP-CLI-5
law status_of:
  for ls: List<&2, String>
  {Http.status.of(ls) == U32.read(Http.second(String.split(Http.first(ls), ' ')))
    : Maybe<&2, U32>}

# LAW (RFC 9110 §15.3.5, §15.4.5): a 204 or a 304 has no body
# HTTP-CLI-5
law status_bare_some:
  for +n: U32
  {Http.status.bare(Some{n}) == Bool.or(U32.is_eq(n, 204), U32.is_eq(n, 304))
    : Bool}

# LAW: a status line that does not parse leaves the framing to the headers
# HTTP-CLI-5
law status_bare_none:
  for m: Maybe<&2, U32>
  for e: {None{} == m : Maybe<&2, U32>}
  {Http.status.bare(m) == False{} : Bool}

# LAW (RFC 9110 §9.3.2, RFC 9112 §6.3 item 1): a reply to HEAD, a 204 and a
# 304 have no body, whatever their fields say
# HTTP-CLI-5
law frame_bare:
  for te: String
  for lens: List<&2, String>
  {Http.frame(True{}, te, lens) == Http.Bare{} : Http.Frame}

# LAW (RFC 9112 §6.3 items 3, 4): Transfer-Encoding chunked frames the body,
# Content-Length or not
# HTTP-CLI-5
law frame_chunked:
  for te: String
  for +lens: List<&2, String>
  for e: {True{} == String.contains(String.to_lower(te), "chunked") : Bool}
  {Http.frame(False{}, te, lens) == Http.Chunked{} : Http.Frame}

# LAW (RFC 9112 §6.3 item 6): otherwise Content-Length values that agree on
# a number frame the body at that many octets
# HTTP-CLI-5
law frame_sized:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {True{} == Http.clen.agree(lens) : Bool}
  for n: Nat
  for e3: {Some{n} == Http.digits.read(Http.first(lens)) : Maybe<&2, Nat>}
  {Http.frame(False{}, te, lens) == Http.Sized{n} : Http.Frame}

# LAW (RFC 9112 §6.3 items 5, 8): Content-Length values that disagree leave
# the body to the close
# HTTP-CLI-5
law frame_disagree:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {False{} == Http.clen.agree(lens) : Bool}
  {Http.frame(False{}, te, lens) == Http.Closed{} : Http.Frame}

# LAW (RFC 9112 §6.3 item 8): no Content-Length, or one that is not a
# number, leaves the body to the close
# HTTP-CLI-5
law frame_unsized:
  for te: String
  for +lens: List<&2, String>
  for e1: {False{} == String.contains(String.to_lower(te), "chunked") : Bool}
  for e2: {True{} == Http.clen.agree(lens) : Bool}
  for e3: {None{} == Http.digits.read(Http.first(lens)) : Maybe<&2, Nat>}
  {Http.frame(False{}, te, lens) == Http.Closed{} : Http.Frame}

# LAW: a response with no body is whole as soon as its head is
# HTTP-CLI-5
law whole_bare:
  for +body: String
  {Http.whole.of(Http.Bare{}, body) == True{} : Bool}

# LAW (RFC 9110 §8.6): a sized body is whole once it holds that many octets
# HTTP-CLI-5
law whole_sized:
  for n: Nat
  for +body: String
  {Http.whole.of(Http.Sized{n}, body)
    == Bool.not(Nat.is_lt(Http.utf8.len(body), n)) : Bool}

# LAW (RFC 9112 §7.1): a chunked body is whole once it reaches the end of its
# last chunk, read from its first chunk header
# HTTP-CLI-5
law whole_chunked:
  for +body: String
  {Http.whole.of(Http.Chunked{}, body)
    == Http.chunks.ended(String.length(body), Http.divide(body, "\r\n"))
    : Bool}

# LAW (RFC 9112 §6.3 item 8): a body framed by the close is never whole
# before the close
# HTTP-CLI-5
law whole_closed:
  for +body: String
  {Http.whole.of(Http.Closed{}, body) == False{} : Bool}

# LAW: a chunk walk with no fuel left has not ended
# HTTP-CLI-5
law ended_fuel:
  for c: Http.Cut
  {Http.chunks.ended(0n, c) == False{} : Bool}

# LAW (RFC 9112 §7.1): a chunk header that has not all arrived has not ended
# HTTP-CLI-5
law ended_open:
  for f: Nat
  {Http.chunks.ended(1n+f, Http.NoCut{}) == False{} : Bool}

# LAW (RFC 9112 §7.1): a chunk size that is not hexadecimal ends the read,
# and the parse rejects it
# HTTP-CLI-5
law ended_bad:
  for f: Nat
  for +before: String
  for +after: String
  for e: {False{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after}) == True{} : Bool}

# LAW (RFC 9112 §7.1.2): the zero-size chunk ends the body once its trailer
# section has ended
# HTTP-CLI-5
law ended_last:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {True{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after})
    == Http.chunks.trailer(after) : Bool}

# LAW (RFC 9112 §7.1): a chunk that has all arrived, with its CRLF, moves on
# to the next chunk header
# HTTP-CLI-5
law ended_next:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {False{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  for e3: {True{} == Http.chunks.ready(after, Http.hexlen(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after})
    == Http.chunks.ended(f, Http.divide(Http.utf8.drop(after,
      Nat.add(Http.hexlen(before), 2n)), "\r\n")) : Bool}

# LAW (RFC 9112 §7.1): a chunk that has not all arrived has not ended
# HTTP-CLI-5
law ended_short:
  for f: Nat
  for +before: String
  for +after: String
  for e1: {True{} == Http.hex.well(Http.chunks.token(before)) : Bool}
  for e2: {False{} == Nat.is_eq(Http.hexlen(before), 0n) : Bool}
  for e3: {False{} == Http.chunks.ready(after, Http.hexlen(before)) : Bool}
  {Http.chunks.ended(1n+f, Http.Cut{before, after}) == False{} : Bool}

# LAW (RFC 9112 §7.1.2): a trailer section has ended at once (CRLF), or after
# its fields (a blank line)
# HTTP-CLI-5
law trailer_ended:
  for +after: String
  {Http.chunks.trailer(after) == Bool.or(String.starts_with(after, "\r\n"),
    String.contains(after, "\r\n\r\n")) : Bool}

# LAW (RFC 9112 §7.1): a chunk of size n has arrived when n octets and a
# CRLF follow its header
# HTTP-CLI-5
law chunk_ready:
  for +after: String
  for +n: Nat
  {Http.chunks.ready(after, n)
    == Bool.and(Bool.not(Nat.is_lt(Http.utf8.len(after), Nat.add(n, 2n))),
      String.starts_with(Http.utf8.drop(after, n), "\r\n")) : Bool}

# --- octet bodies on the wire (SPEC.md HTTP-CLI-10) ---

# LAW: a text body is sent inside the request text, as HTTP-CLI-4 says
# HTTP-CLI-10
law exchange_body_text:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  for text: String
  {Spec.wire.exchange.body(method, l, hs, Body.Plain{text})
    == Spec.wire.exchange(method, l, hs, text) : Spec.Exchange}

# LAW: an empty body is sent as the empty text body
# HTTP-CLI-10
law exchange_body_empty:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  {Spec.wire.exchange.body(method, l, hs, Body.Empty{})
    == Spec.wire.exchange(method, l, hs, "") : Spec.Exchange}

# LAW: an octet body's request text is built for its number of octets
# HTTP-CLI-10
law exchange_body_octets:
  for method: String
  for l: Url.Loc
  for hs: List<&2, Http.Header>
  for +bytes: List<&2, U32>
  {Spec.wire.exchange.body(method, l, hs, Body.Octets{bytes})
    == Spec.wire.exchange.octets(method, l, hs, List.length(&2, U32, bytes))
    : Spec.Exchange}

# LAW: a URL that does not parse sends nothing and keeps its reason
# HTTP-CLI-10
law exchange_octets_bad:
  for method: String
  for why: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Spec.wire.exchange.octets(method, Url.Bad{why}, hs, n) == Spec.NoUrl{why}
    : Spec.Exchange}

# LAW: a URL that parses is sent to its host and port, over TLS exactly when
# its scheme is https, with the method it was given and the request text
# request.head.at writes for n octets
# HTTP-CLI-10
law exchange_octets_loc:
  for +method: String
  for +scheme: String
  for +host: String
  for +port: U32
  for path: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Spec.wire.exchange.octets(method, Url.Loc{scheme, host, port, path}, hs, n)
    == Spec.Exchange{String.eq(scheme, "https"), host, port, method,
      Http.request.head.at(method, String.eq(scheme, "https"), host, port,
        path, hs, n)} : Spec.Exchange}

# LAW (RFC 9112 §3): the request text ahead of n octets is the request line,
# the header fields for n octets, and the blank line, nothing after it
# HTTP-CLI-10
law request_head_at:
  for +method: String
  for secure: Bool
  for host: String
  for port: U32
  for +path: String
  for hs: List<&2, Http.Header>
  for n: Nat
  {Http.request.head.at(method, secure, host, port, path, hs, n)
    == method ++ " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(
        Http.request.fields.n(Http.authority(secure, host, port), hs, n))
      ++ "\r\n"
    : String}

# LAW (RFC 9110 §8.6): a text body's header fields are the fields for its
# UTF-8 octets
# HTTP-CLI-10
law fields_n:
  for host: String
  for +hs: List<&2, Http.Header>
  for +body: String
  {Http.request.fields(host, hs, body)
    == Http.request.fields.n(host, hs, Http.utf8.len(body))
    : List<&2, Http.Header>}

# LAW (RFC 9110 §8.6): whatever the caller gave, the Content-Length fields for
# n octets are exactly `Content-Length: n`, and none for none
# HTTP-CLI-10
law fields_clen_n:
  for +host: String
  for +hs: List<&2, Http.Header>
  for +n: Nat
  {Http.fields.of(Http.FClen{}, Http.request.fields.n(host, hs, n))
    == Http.clen.field(n, Nat.is_eq(n, 0n)) : List<&2, Http.Header>}

# LAW: an octet body's octets are the tail sent after the request text
# HTTP-CLI-10
law tail_octets:
  for bytes: List<&2, U32>
  {Spec.wire.tail(Body.Octets{bytes}) == bytes : List<&2, U32>}

# LAW: a text body has no tail
# HTTP-CLI-10
law tail_text:
  for text: String
  {Spec.wire.tail(Body.Plain{text}) == [] : List<&2, U32>}

# LAW: an empty body has no tail
# HTTP-CLI-10
law tail_empty:
  for b: Body.Body
  for e: {Body.Empty{} == b : Body.Body}
  {Spec.wire.tail(b) == [] : List<&2, U32>}

# --- the response, read by the request's method (SPEC.md HTTP-CLI-9) ---

# LAW: a response is read head by head for the request's method, at most as
# many heads as the text has characters
# HTTP-CLI-9
law reply_to:
  for +method: String
  for +raw: String
  {Http.parse.to(method, raw)
    == Http.parse.to.go(String.length(raw), String.eq(method, "HEAD"),
      Http.divide(raw, "\r\n\r\n")) : Http.Reply}

# LAW: a read with no heads left found no final head
# HTTP-CLI-9
law reply_fuel:
  for head: Bool
  for c: Http.Cut
  {Http.parse.to.go(0n, head, c)
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}

# LAW (RFC 9112 §2.1): a head that never ends is torn
# HTTP-CLI-9
law reply_open:
  for f: Nat
  for head: Bool
  {Http.parse.to.go(1n+f, head, Http.NoCut{})
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}

# LAW (RFC 9110 §15.2): an interim head with text after it is skipped, and the
# text after it is read in its place
# HTTP-CLI-9
law reply_interim:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e: {True{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.parse.to.go(f, head, Http.divide(after, "\r\n\r\n")) : Http.Reply}

# LAW (RFC 9110 §6.4.1, §9.3.2; RFC 9112 §6.3 item 1): a final response to
# HEAD, or with a 1xx, 204 or 304 status, has its status, its fields and no
# body, whatever its framing fields say
# HTTP-CLI-9
law reply_bare:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {True{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  for n: U32
  for e3: {Some{n} == Http.status.of(String.lines(before)) : Maybe<&2, U32>}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.Reply{n, Http.head.list(String.lines(before)), ""} : Http.Reply}

# LAW (RFC 9112 §4): a final head with no status code is torn
# HTTP-CLI-9
law reply_bare_none:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {True{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  for e3: {None{} == Http.status.of(String.lines(before)) : Maybe<&2, U32>}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.Torn{"the response has no status line"} : Http.Reply}

# LAW: any other final response is read as parse_response reads that head and
# the text after it
# HTTP-CLI-9
law reply_framed:
  for f: Nat
  for +head: Bool
  for +before: String
  for +after: String
  for e1: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  for e2: {False{} == Bool.or(head,
    Http.status.empty(Http.status.of(String.lines(before)))) : Bool}
  {Http.parse.to.go(1n+f, head, Http.Cut{before, after})
    == Http.parse.head(String.lines(before), after) : Http.Reply}

# LAW (RFC 9110 §15.2): a head is skipped exactly when it is interim and text
# follows it
# HTTP-CLI-9
law interim_skip:
  for m: Maybe<&2, U32>
  for after: String
  {Http.interim.skip(m, after)
    == Bool.and(Http.status.interim(m), Bool.not(String.is_empty(after)))
    : Bool}

# LAW (RFC 9110 §6.4.1): a 1xx, 204 or 304 status has no body
# HTTP-CLI-9
law status_empty:
  for +m: Maybe<&2, U32>
  {Http.status.empty(m)
    == Bool.or(Http.status.interim(m), Http.status.bare(m)) : Bool}

# LAW: a successful exchange's text is read by the request's method
# HTTP-CLI-9
law heard_ok:
  for +method: String
  for +text: String
  {Spec.wire.heard(method, "0\n" ++ text) == Http.parse.to(method, text)
    : Http.Reply}

# LAW: a failed exchange is torn with the reason it is reported with
# HTTP-CLI-9
law heard_fail:
  for +method: String
  for +raw: String
  for e: {False{} == Spec.wire.ok(raw) : Bool}
  {Spec.wire.heard(method, raw)
    == Http.Torn{Spec.wire.why(Spec.wire.code(raw), Spec.wire.text(raw))}
    : Http.Reply}

# --- a response's reason phrase (SPEC.md HTTP-CLI-11) ---

# LAW: a text's reason phrase is read head by head, at most as many heads as
# it has characters
# HTTP-CLI-11
law phrase_to:
  for +raw: String
  {Http.phrase.to(raw)
    == Http.phrase.to.go(String.length(raw), Http.divide(raw, "\r\n\r\n"))
    : String}

# LAW: a read with no heads left found no reason
# HTTP-CLI-11
law phrase_fuel:
  for c: Http.Cut
  {Http.phrase.to.go(0n, c) == "" : String}

# LAW (RFC 9112 §2.1): a head that never ends has no reason
# HTTP-CLI-11
law phrase_open:
  for f: Nat
  {Http.phrase.to.go(1n+f, Http.NoCut{}) == "" : String}

# LAW (RFC 9110 §15.2): an interim head with text after it is skipped by the
# same rule HTTP-CLI-9 skips it by, and the reason read from the text after it
# HTTP-CLI-11
law phrase_interim:
  for f: Nat
  for +before: String
  for +after: String
  for e: {True{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.phrase.to.go(1n+f, Http.Cut{before, after})
    == Http.phrase.to.go(f, Http.divide(after, "\r\n\r\n")) : String}

# LAW: the head HTTP-CLI-9 stops at gives the reason on its status line
# HTTP-CLI-11
law phrase_final:
  for f: Nat
  for +before: String
  for +after: String
  for e: {False{} == Http.interim.skip(Http.status.of(String.lines(before)),
    after) : Bool}
  {Http.phrase.to.go(1n+f, Http.Cut{before, after})
    == Http.phrase.line(Http.first(String.lines(before))) : String}

# LAW (RFC 9112 §4): a status line `<v> SP <c> SP <r>` whose version and code
# hold no SP and whose reason holds no CR has reason exactly r
# HTTP-CLI-11
law phrase_line:
  for +v: String
  for +c: String
  for +r: String
  for e1: {True{} == avoids(v, ' ') : Bool}
  for e2: {True{} == avoids(c, ' ') : Bool}
  for e3: {True{} == avoids(r, '\r') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c ++ SCon{' ', r}}) == r : String}

# LAW (RFC 9112 §4): the CR that ends a status line's CRLF is not part of
# its reason
# HTTP-CLI-11
law phrase_line_cr:
  for +v: String
  for +c: String
  for +r: String
  for e1: {True{} == avoids(v, ' ') : Bool}
  for e2: {True{} == avoids(c, ' ') : Bool}
  for e3: {True{} == avoids(r, '\r') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c ++ SCon{' ', r ++ "\r"}}) == r : String}

# LAW: a status line with one SP has an empty reason
# HTTP-CLI-11
law phrase_line_one:
  for +v: String
  for +c: String
  for e1: {True{} == avoids(v, ' ') : Bool}
  for e2: {True{} == avoids(c, ' ') : Bool}
  {Http.phrase.line(v ++ SCon{' ', c}) == "" : String}

# LAW: a status line with no SP has an empty reason
# HTTP-CLI-11
law phrase_line_none:
  for +v: String
  for e: {True{} == avoids(v, ' ') : Bool}
  {Http.phrase.line(v) == "" : String}

# LAW: the client reads the reason from the same text it reads the response
# from
# HTTP-CLI-11
law phrase_heard:
  for +text: String
  {Spec.wire.phrase("0\n" ++ text) == Http.phrase.to(text) : String}

# --- reading until the response is whole (SPEC.md HTTP-CLI-6) ---

# LAW: an open that fails is the exchange's answer as the effect gave it
# HTTP-CLI-6
law opened_fail:
  for +got: String
  for e: {False{} == Spec.wire.ok(got) : Bool}
  {Spec.wire.opened(got) == Spec.Refused{got} : Spec.Opened}

# LAW: an open that succeeds names the connection to read from
# HTTP-CLI-6
law opened_conn:
  for n: U32
  for +text: String
  for e: {Some{n} == U32.read(text) : Maybe<&2, U32>}
  {Spec.wire.opened("0\n" ++ text) == Spec.Open{n} : Spec.Opened}

# LAW: a read that fails is the exchange's answer as the effect gave it
# HTTP-CLI-6
law read_fail:
  for st: Spec.Got
  for +got: String
  for e: {False{} == Spec.wire.ok(got) : Bool}
  {Spec.wire.read.next(st, got) == Spec.Heard{got} : Spec.Read}

# LAW: a read that finds the connection closed answers everything received
# HTTP-CLI-6
law read_closed:
  for ps: List<&2, String>
  for h: Http.Hear
  {Spec.wire.read.next(Spec.Got{ps, h}, "0\n")
    == Spec.Heard{"0\n" ++ Spec.wire.joined(ps)} : Spec.Read}

# LAW: a read whose text completes the response answers all of it
# HTTP-CLI-6
law read_whole:
  for +method: String
  for +ps: List<&2, String>
  for +text: String
  for e1: {False{} == String.is_empty(text) : Bool}
  for e2: {True{} == Http.whole(method, Spec.wire.joined(ps) ++ text) : Bool}
  {Spec.wire.read.next(Spec.wire.got(method, ps), "0\n" ++ text)
    == Spec.Heard{"0\n" ++ (Spec.wire.joined(ps) ++ text)} : Spec.Read}

# LAW: a read whose text does not complete the response reads again with it
# added, in the state for what has been received with it
# HTTP-CLI-6
law read_more:
  for +method: String
  for +ps: List<&2, String>
  for +text: String
  for e1: {False{} == String.is_empty(text) : Bool}
  for e2: {False{} == Http.whole(method, Spec.wire.joined(ps) ++ text) : Bool}
  {Spec.wire.read.next(Spec.wire.got(method, ps), "0\n" ++ text)
    == Spec.Again{Spec.wire.got(method, text <> ps)} : Spec.Read}

# LAW: the pieces put together in one pass are the text they stand for
# HTTP-CLI-6
law join_joined:
  for +ps: List<&2, String>
  {Spec.wire.join(ps) == Spec.wire.joined(ps) : String}

# --- judging a response read by read (SPEC.md HTTP-CLI-12) ---

# LAW: the state for a text says the response is complete exactly when the
# whole-text check (HTTP-CLI-5) says that text is
# HTTP-CLI-12
law hear_done:
  for +method: String
  for +raw: String
  {Http.hear.done(Http.hear.of(method, raw)) == Http.whole(method, raw)
    : Bool}

# LAW: the state for a text, advanced by more text, is the state for the two
# together
# HTTP-CLI-12
law hear_more:
  for +method: String
  for +a: String
  for +b: String
  {Http.hear.more(Http.hear.of(method, a), b) == Http.hear.of(method, a ++ b)
    : Http.Hear}

# LAW (RFC 9112 §7.1): a chunked body's walk from a chunk header has ended
# exactly when chunks.ended says, with the same fuel
# HTTP-CLI-12
law walk_done:
  for f: Nat
  for +rest: String
  {Http.walk.done(Http.walk(f, rest))
    == Http.chunks.ended(f, Http.divide(rest, "\r\n")) : Bool}

# LAW: the walk over a text and more text, with fuel for both, is the walk
# over the text advanced by the more
# HTTP-CLI-12
law walk_more:
  for f: Nat
  for +rest: String
  for +b: String
  {Http.walk(Nat.add(f, String.length(b)), rest ++ b)
    == Http.walk.more(Http.walk(f, rest), String.length(b), b) : Http.Walk}

# --- redirects (SPEC.md HTTP-REDIR) ---

# LAW: a redirect status, with hops left, whose Location has a target goes to
# exactly that target
# HTTP-REDIR-1
law redir_go:
  for +status: U32
  for e: {True{} == Bool.or(U32.is_eq(status, 301), Bool.or(U32.is_eq(status,
    302), Bool.or(U32.is_eq(status, 303), Bool.or(U32.is_eq(status, 307),
    U32.is_eq(status, 308))))) : Bool}
  for n: Nat
  for url: String
  for +loc: String
  for next: String
  for et: {Some{next} == Redirect.redirect.target(url, loc)
    : Maybe<&2, String>}
  {Redirect.redirect.next(1n+n, url, status, loc) == Redirect.Go{next}
    : Redirect.Hop}

# LAW: a redirect whose Location has no target stops the chain
# HTTP-REDIR-1
law redir_no_target:
  for +status: U32
  for left: Nat
  for url: String
  for +loc: String
  for et: {None{} == Redirect.redirect.target(url, loc) : Maybe<&2, String>}
  {Redirect.redirect.next(left, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}

# LAW: the Location the planner reads is the response's Location header
# (case-insensitive, "" when absent)
# HTTP-REDIR-1
law redir_plan_location:
  for left: Nat
  for url: String
  for +status: U32
  for hs: List<&2, Http.Header>
  {Redirect.redirect.plan(left, url, status, hs)
    == Redirect.redirect.next(left, url, status,
      Http.headers.find(hs, "location")) : Redirect.Hop}

# LAW: every status other than 301, 302, 303, 307 and 308 stops the chain
# HTTP-REDIR-2
law redir_other:
  for +status: U32
  for e: {False{} == Bool.or(U32.is_eq(status, 301), Bool.or(U32.is_eq(status,
    302), Bool.or(U32.is_eq(status, 303), Bool.or(U32.is_eq(status, 307),
    U32.is_eq(status, 308))))) : Bool}
  for left: Nat
  for url: String
  for +loc: String
  {Redirect.redirect.next(left, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}

# LAW: with no hops left the chain stops, whatever the response
# HTTP-REDIR-2
law redir_zero:
  for url: String
  for +status: U32
  for +loc: String
  {Redirect.redirect.next(0n, url, status, loc) == Redirect.Stop{}
    : Redirect.Hop}

# LAW: an absolute http or https Location is its own target
# HTTP-REDIR-3
law target_absolute:
  for url: String
  for +loc: String
  for e: {True{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  {Redirect.redirect.target(url, loc) == Some{loc} : Maybe<&2, String>}

# LAW: against a URL that does not parse, a Location that is not an absolute
# URL has no target
# HTTP-REDIR-3
law target_bad:
  for url: String
  for +loc: String
  for e1: {False{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  for why: String
  for e2: {Url.Bad{why} == Url.parse(url) : Url.Loc}
  {Redirect.redirect.target(url, loc) == None{} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): against a URL that parses, a Location that is not an
# absolute URL is resolved by its sort against the URL's parts
# HTTP-REDIR-3
# HTTP-REDIR-4
law target_against:
  for url: String
  for +loc: String
  for e1: {False{} == Bool.or(String.starts_with(loc, "http://"),
    String.starts_with(loc, "https://")) : Bool}
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for e2: {Url.Loc{scheme, host, port, path} == Url.parse(url) : Url.Loc}
  {Redirect.redirect.target(url, loc)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): a network-path reference keeps only the scheme
# HTTP-REDIR-3
law against_net:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Net{})
    == Some{scheme ++ ":" ++ loc} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): an absolute path keeps the origin, its own path with
# dot segments removed, then its query
# HTTP-REDIR-3
law against_abs:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Abs{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.abs.of(Redirect.redirect.split(loc))}
    : Maybe<&2, String>}

# LAW: a Location the client stays on has no target
# HTTP-REDIR-3
law against_stay:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Stay{})
    == None{} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): a query keeps the origin and the current path
# HTTP-REDIR-4
law against_query:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Query{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.base(path) ++ loc} : Maybe<&2, String>}

# LAW (RFC 3986 §5.2.2): a relative path keeps the origin and is merged with
# the current path
# HTTP-REDIR-4
law against_rel:
  for scheme: String
  for host: String
  for port: U32
  for path: String
  for +loc: String
  {Redirect.redirect.against(scheme, host, port, path, loc, Redirect.Rel{})
    == Some{scheme ++ "://" ++ host ++ ":" ++ U32.show(port)
      ++ Redirect.redirect.rel.of(Redirect.redirect.base(path),
        Redirect.redirect.split(loc))} : Maybe<&2, String>}

# LAW (RFC 3986 §4.2): a Location that starts `//` is a network path
# HTTP-REDIR-3
law sort_net:
  for +loc: String
  for e: {True{} == String.starts_with(loc, "//") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Net{} : Redirect.Sort}

# LAW (RFC 3986 §4.2): one that starts with a single `/` is an absolute path
# HTTP-REDIR-3
law sort_abs:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {True{} == String.starts_with(loc, "/") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Abs{} : Redirect.Sort}

# LAW: any other Location the client does not follow stays
# HTTP-REDIR-3
law sort_stay:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {True{} == Redirect.redirect.stays(loc) : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Stay{} : Redirect.Sort}

# LAW (RFC 3986 §4.2): any other Location that starts `?` is a query
# HTTP-REDIR-4
law sort_query:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {False{} == Redirect.redirect.stays(loc) : Bool}
  for e4: {True{} == String.starts_with(loc, "?") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Query{} : Redirect.Sort}

# LAW (RFC 3986 §4.2): and every other one is a relative path
# HTTP-REDIR-4
law sort_rel:
  for +loc: String
  for e1: {False{} == String.starts_with(loc, "//") : Bool}
  for e2: {False{} == String.starts_with(loc, "/") : Bool}
  for e3: {False{} == Redirect.redirect.stays(loc) : Bool}
  for e4: {False{} == String.starts_with(loc, "?") : Bool}
  {Redirect.redirect.sort(loc) == Redirect.Rel{} : Redirect.Sort}

# LAW: the client stays on an empty Location, a fragment, and one that names
# another scheme
# HTTP-REDIR-3
law stays_on:
  for +loc: String
  {Redirect.redirect.stays(loc) == Bool.or(String.is_empty(loc),
    Bool.or(String.starts_with(loc, "#"), Redirect.redirect.schemed(loc)))
    : Bool}

# LAW (RFC 3986 §3.1): an empty reference names no scheme
# HTTP-REDIR-3
law schemed_nil:
  for s: String
  for e: {True{} == String.is_empty(s) : Bool}
  {Redirect.redirect.schemed(s) == False{} : Bool}

# LAW (RFC 3986 §3.1): a `:` before the first `/`, `?` or `#` names a scheme
# HTTP-REDIR-3
law schemed_colon:
  for t: String
  {Redirect.redirect.schemed(SCon{':', t}) == True{} : Bool}

# LAW (RFC 3986 §4.2): a `/`, `?` or `#` first means no scheme
# HTTP-REDIR-3
law schemed_stop:
  for +c: Char
  for t: String
  for e: {True{} == Redirect.redirect.schemed.end(c) : Bool}
  {Redirect.redirect.schemed(SCon{c, t}) == False{} : Bool}

# LAW: any other first character leaves the question to the rest
# HTTP-REDIR-3
law schemed_other:
  for +c: Char
  for t: String
  for e1: {False{} == Char.is_eq(c, ':') : Bool}
  for e2: {False{} == Redirect.redirect.schemed.end(c) : Bool}
  {Redirect.redirect.schemed(SCon{c, t}) == Redirect.redirect.schemed(t)
    : Bool}

# LAW: the characters that end a reference's first segment are `/`, `?`, `#`
# HTTP-REDIR-3
law schemed_end:
  for +c: Char
  {Redirect.redirect.schemed.end(c) == Bool.or(Char.is_eq(c, '/'),
    Bool.or(Char.is_eq(c, '?'), Char.is_eq(c, '#'))) : Bool}

# LAW (RFC 3986 §3.4, §3.5): a Location with a `?` is its path before it and
# its query from it, its fragment dropped
# HTTP-REDIR-3
# HTTP-REDIR-4
law split_query:
  for +loc: String
  for p: String
  for q: String
  for e: {Http.Cut{p, q} == Http.divide(Url.frag.drop(loc), "?") : Http.Cut}
  {Redirect.redirect.split(loc) == Redirect.Ref{p, "?" ++ q} : Redirect.Ref}

# LAW: a Location with no `?` is all path, its fragment dropped
# HTTP-REDIR-3
# HTTP-REDIR-4
law split_plain:
  for +loc: String
  for e: {Http.NoCut{} == Http.divide(Url.frag.drop(loc), "?") : Http.Cut}
  {Redirect.redirect.split(loc) == Redirect.Ref{Url.frag.drop(loc), ""}
    : Redirect.Ref}

# LAW (RFC 3986 §5.2.2): an absolute path is its segments after the leading
# `/`, dot segments removed, then its query
# HTTP-REDIR-3
law abs_of:
  for path: String
  for query: String
  {Redirect.redirect.abs.of(Redirect.Ref{path, query})
    == Redirect.redirect.clean(List.tail(&2, String, String.split(path, '/')))
      ++ query : String}

# LAW (RFC 3986 §5.2.3): a relative path follows every segment of the current
# path but its last, then dot segments are removed, then its query
# HTTP-REDIR-4
law rel_of:
  for base: String
  for path: String
  for query: String
  {Redirect.redirect.rel.of(base, Redirect.Ref{path, query})
    == Redirect.redirect.clean(List.tail(&2, String,
      List.append(&2, String, Redirect.redirect.init(String.split(base, '/')),
        String.split(path, '/')))) ++ query : String}

# LAW: the current path, for merging, is the part before its `?`
# HTTP-REDIR-4
law base_path:
  for path: String
  {Redirect.redirect.base(path) == Url.query.hier(String.split(path, '?'))
    : String}

# LAW: the first piece of a split, empty when there is none
# HTTP-REDIR-4
law hier_first:
  for h: String
  for t: List<&2, String>
  {Url.query.hier(h <> t) == h : String}

# LAW: no segments have no segments but the last
# HTTP-REDIR-4
law init_nil:
  for ss: List<&2, String>
  for e: {True{} == List.is_empty(&2, String, ss) : Bool}
  {Redirect.redirect.init(ss) == [] : List<&2, String>}

# LAW: segments but the last start from the first
# HTTP-REDIR-4
law init_cons:
  for s: String
  for t: List<&2, String>
  {Redirect.redirect.init(s <> t) == Redirect.redirect.init.of(t, s)
    : List<&2, String>}

# LAW: the last segment is dropped
# HTTP-REDIR-4
law init_last:
  for s: String
  {Redirect.redirect.init.of([], s) == [] : List<&2, String>}

# LAW: every segment before the last is kept, in order
# HTTP-REDIR-4
law init_keep:
  for s: String
  for u: String
  for r: List<&2, String>
  {Redirect.redirect.init.of(u <> r, s) == s <> Redirect.redirect.init.of(r, u)
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4): a path is `/`, then its segments with dot segments
# removed, joined by `/`
# HTTP-REDIR-5
law clean_path:
  for ss: List<&2, String>
  {Redirect.redirect.clean(ss)
    == "/" ++ String.join(Redirect.redirect.dots(ss, []), "/") : String}

# LAW: once every segment is read, the kept ones are the path, in order
# HTTP-REDIR-5
law dots_nil:
  for out: List<&2, String>
  {Redirect.redirect.dots([], out) == List.reverse(&2, String, out)
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 B, D): a `.` segment is dropped
# HTTP-REDIR-5
law dots_dot:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e: {True{} == String.eq(s, ".") : Bool}
  {Redirect.redirect.dots(s <> t, out)
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t), out))
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C, D): a `..` segment drops the last segment kept
# HTTP-REDIR-5
law dots_up:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e1: {False{} == String.eq(s, ".") : Bool}
  for e2: {True{} == String.eq(s, "..") : Bool}
  {Redirect.redirect.dots(s <> t, out)
    == Redirect.redirect.dots(t,
      Redirect.redirect.dots.end(List.is_empty(&2, String, t),
        Redirect.redirect.pop(out))) : List<&2, String>}

# LAW (RFC 3986 §5.2.4 E): every other segment is kept
# HTTP-REDIR-5
law dots_seg:
  for +s: String
  for +t: List<&2, String>
  for out: List<&2, String>
  for e1: {False{} == String.eq(s, ".") : Bool}
  for e2: {False{} == String.eq(s, "..") : Bool}
  {Redirect.redirect.dots(s <> t, out) == Redirect.redirect.dots(t, s <> out)
    : List<&2, String>}

# LAW (RFC 3986 §5.2.4 B, C): a path that ends in `.` or `..` keeps its
# trailing `/`
# HTTP-REDIR-5
law dots_last:
  for out: List<&2, String>
  {Redirect.redirect.dots.end(True{}, out) == "" <> out : List<&2, String>}

# LAW: a `.` or `..` before other segments adds nothing
# HTTP-REDIR-5
law dots_inner:
  for out: List<&2, String>
  {Redirect.redirect.dots.end(False{}, out) == out : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C): `..` with nothing kept drops nothing
# HTTP-REDIR-5
law pop_nil:
  for out: List<&2, String>
  for e: {True{} == List.is_empty(&2, String, out) : Bool}
  {Redirect.redirect.pop(out) == [] : List<&2, String>}

# LAW (RFC 3986 §5.2.4 C): `..` drops the last segment kept
# HTTP-REDIR-5
law pop_cons:
  for s: String
  for t: List<&2, String>
  {Redirect.redirect.pop(s <> t) == t : List<&2, String>}

# --- HTML escaping (SPEC.md HTTP-HTML) ---

# LAW: escaping a string is escaping it in front of nothing
# HTTP-HTML-1
law html_escape_onto:
  for s: String
  {Html.escape(s) == Html.escape.onto(s, "") : String}

# LAW: nothing is written for the empty string
# HTTP-HTML-1
law html_nil:
  for rest: String
  {Html.escape.onto("", rest) == rest : String}

# LAW: a string is written one character at a time, the first character's
# writing followed by the rest's
# HTTP-HTML-1
law html_cons:
  for +c: Char
  for t: String
  for rest: String
  {Html.escape.onto(SCon{c, t}, rest) == Html.one(c, Html.escape.onto(t, rest))
    : String}

# LAW: `&` is written as `&amp;`
# HTTP-HTML-2
law html_amp:
  for rest: String
  {Html.one('&', rest) == "&amp;" ++ rest : String}

# LAW: `<` is written as `&lt;`
# HTTP-HTML-2
law html_lt:
  for rest: String
  {Html.one('<', rest) == "&lt;" ++ rest : String}

# LAW: `>` is written as `&gt;`
# HTTP-HTML-2
law html_gt:
  for rest: String
  {Html.one('>', rest) == "&gt;" ++ rest : String}

# LAW: `"` is written as `&#34;`
# HTTP-HTML-2
law html_dq:
  for rest: String
  {Html.one('"', rest) == "&#34;" ++ rest : String}

# LAW: `'` is written as `&#39;`
# HTTP-HTML-2
law html_sq:
  for rest: String
  {Html.one('\'', rest) == "&#39;" ++ rest : String}

# LAW: every other character is written as itself
# HTTP-HTML-3
law html_other:
  for +c: Char
  for e1: {False{} == Char.is_eq(c, '&') : Bool}
  for e2: {False{} == Char.is_eq(c, '<') : Bool}
  for e3: {False{} == Char.is_eq(c, '>') : Bool}
  for e4: {False{} == Char.is_eq(c, '"') : Bool}
  for e5: {False{} == Char.is_eq(c, '\'') : Bool}
  for rest: String
  {Html.one(c, rest) == SCon{c, rest} : String}

# where the HTTP-HTML-4 frame is, reading left to right: between entities,
# after `&`, after `&#`, after `&#3`, or owing exactly the rest of an entity
type Ent is Data:
  Out{}
  Amp{}
  Hash{}
  Three{}
  Want{c: Char, rest: String}

# between entities: anything but `<`, `>`, `"` and `'`
def ent.out.ok(lt: Bool, gt: Bool, dq: Bool, sq: Bool) -> Bool:
  Bool.not(Bool.or(lt, Bool.or(gt, Bool.or(dq, sq))))

# between entities, an `&` opens one
def ent.out.next(amp: Bool) -> Ent:
  Bool.pick(Ent, amp, Amp{}, Out{})

# what is owed after the rest of an entity's next character
def ent.want(rest: String) -> Ent:
  match rest:
    case SNil{}:
      Out{}
    case SCon{c, t}:
      Want{c, t}

# whether character c may come next
def ent.ok(+c: Char, st: Ent) -> Bool:
  match st:
    case Out{}:
      ent.out.ok(Char.is_eq(c, '<'), Char.is_eq(c, '>'), Char.is_eq(c, '"'),
        Char.is_eq(c, '\''))
    case Amp{}:
      Bool.or(Char.is_eq(c, 'a'), Bool.or(Char.is_eq(c, 'l'),
        Bool.or(Char.is_eq(c, 'g'), Char.is_eq(c, '#'))))
    case Hash{}:
      Char.is_eq(c, '3')
    case Three{}:
      Bool.or(Char.is_eq(c, '4'), Char.is_eq(c, '9'))
    case Want{w, t}:
      Char.is_eq(c, w)

# where the frame is after character c
def ent.next(+c: Char, st: Ent) -> Ent:
  match st:
    case Out{}:
      ent.out.next(Char.is_eq(c, '&'))
    case Amp{}:
      Bool.pick(Ent, Char.is_eq(c, 'a'), Want{'m', "p;"},
        Bool.pick(Ent, Char.is_eq(c, '#'), Hash{}, Want{'t', ";"}))
    case Hash{}:
      Three{}
    case Three{}:
      Want{';', ""}
    case Want{w, t}:
      ent.want(t)

# nothing is owed at the end
def ent.end(st: Ent) -> Bool:
  match st:
    case Out{}:
      True{}
    case Amp{}:
      False{}
    case Hash{}:
      False{}
    case Three{}:
      False{}
    case Want{w, t}:
      False{}

# the HTTP-HTML-4 frame: no `<`, `>`, `"` or `'`, and every `&` opens one of
# `&amp;`, `&lt;`, `&gt;`, `&#34;`, `&#39;`
def html.framed(str: String, +st: Ent) -> Bool:
  match str:
    case SNil{}:
      ent.end(st)
    case SCon{+c, tail}:
      Bool.and(ent.ok(c, st), html.framed(tail, ent.next(c, st)))

# LAW (frame): every escaped string holds no `<`, `>`, `"` or `'`, and each
# `&` in it opens one of the five entities
# HTTP-HTML-4
law html_frame:
  for s: String
  {html.framed(Html.escape(s), Out{}) == True{} : Bool}

# --- which requests follow redirects (SPEC.md HTTP-REDIR-6) ---

# LAW: a GET follows redirects exactly when it is asked to
# HTTP-REDIR-6
law follows_get:
  for follow: Bool
  {Redirect.redirect.follows("GET", follow) == follow : Bool}

# LAW (RFC 9110 §9.1): every other method never follows redirects
# HTTP-REDIR-6
law follows_other:
  for +method: String
  for e: {False{} == String.eq(method, "GET") : Bool}
  for follow: Bool
  {Redirect.redirect.follows(method, follow) == False{} : Bool}

# --- multipart/form-data bodies (SPEC.md HTTP-FORM) ---

# LAW: a boundary that is not valid is refused
# HTTP-FORM-1
law form_bad_boundary:
  for +b: String
  for ps: List<&2, Form.Part>
  for e: {False{} == Form.form.boundary.ok(b) : Bool}
  {Form.form.body(b, ps)
    == Form.NoForm{"the boundary must be 1 to 70 of A-Z a-z 0-9 - _ ."}
    : Form.Form}

# LAW: a valid boundary whose delimiter occurs in a part's content is refused
# HTTP-FORM-1
law form_clash:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {True{} == Form.form.clash(b, ps) : Bool}
  {Form.form.body(b, ps) == Form.NoForm{"the boundary occurs in a part's content"}
    : Form.Form}

# LAW: a file part whose content type holds a CR or LF is refused
# HTTP-FORM-1
law form_bad_type:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {False{} == Form.form.clash(b, ps) : Bool}
  for e3: {True{} == Form.form.badtype(ps) : Bool}
  {Form.form.body(b, ps)
    == Form.NoForm{"a file part's content type holds a CR or LF"} : Form.Form}

# LAW (RFC 7578 §4.1): every other form is built: its Content-Type value and
# its parts as octets
# HTTP-FORM-1
law form_ok:
  for +b: String
  for +ps: List<&2, Form.Part>
  for e1: {True{} == Form.form.boundary.ok(b) : Bool}
  for e2: {False{} == Form.form.clash(b, ps) : Bool}
  for e3: {False{} == Form.form.badtype(ps) : Bool}
  {Form.form.body(b, ps)
    == Form.Form{Form.form.type(b), Body.Octets{Form.form.parts(b, ps)}}
    : Form.Form}

# LAW (RFC 7578 §4.1): the Content-Type field value names the boundary
# HTTP-FORM-1
law form_type:
  for b: String
  {Form.form.type(b) == "multipart/form-data; boundary=" ++ b : String}

# LAW (RFC 2046 §5.1.1): a boundary is 1 to 70 boundary characters
# HTTP-FORM-2
law boundary_ok:
  for +b: String
  {Form.form.boundary.ok(b)
    == Bool.and(Bool.and(Bool.not(String.is_empty(b)),
      Nat.is_le(String.length(b), 70n)), Form.form.bchars(b)) : Bool}

# LAW: the boundary characters are A-Z, a-z, 0-9, `-`, `_` and `.`
# HTTP-FORM-2
law bchar:
  for +cp: U32
  {Form.form.bchar(cp)
    == Bool.or(Bool.and(U32.is_le(65, cp), U32.is_le(cp, 90)),
      Bool.or(Bool.and(U32.is_le(97, cp), U32.is_le(cp, 122)),
        Bool.or(Bool.and(U32.is_le(48, cp), U32.is_le(cp, 57)),
          Bool.or(U32.is_eq(cp, 45),
            Bool.or(U32.is_eq(cp, 95), U32.is_eq(cp, 46)))))) : Bool}

# LAW: the empty string has no character that is not a boundary character
# HTTP-FORM-2
law bchars_nil:
  for s: String
  for e: {SNil{} == s : String}
  {Form.form.bchars(s) == True{} : Bool}

# LAW: a string's characters are boundary characters exactly when its first
# is and the rest's are
# HTTP-FORM-2
law bchars_cons:
  for +c: U32
  for t: String
  {Form.form.bchars(SCon{Chr{c}, t})
    == Bool.and(Form.form.bchar(c), Form.form.bchars(t)) : Bool}

# LAW (RFC 2046 §5.1.1): the delimiter is `--` and the boundary, as octets
# HTTP-FORM-2
law delim:
  for b: String
  {Form.form.delim(b) == Form.octets.onto("--" ++ b, []) : List<&2, U32>}

# LAW: no parts, no clash
# HTTP-FORM-2
law clash_nil:
  for b: String
  {Form.form.clash(b, []) == False{} : Bool}

# LAW: a list of parts clashes exactly when its first part's content holds
# the delimiter or the rest clashes
# HTTP-FORM-2
law clash_cons:
  for +b: String
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.clash(b, p <> t)
    == Bool.or(Form.octets.has(Form.form.content(p, []), Form.form.delim(b)),
      Form.form.clash(b, t)) : Bool}

# LAW: a check of this and the rest holds exactly when both do
# HTTP-FORM-2
law all_step:
  for ok: Bool
  for rest: Unit -> Bool
  {Form.all.step(ok, rest) == Bool.and(ok, rest(Unit{})) : Bool}

# LAW: a search of this and the rest hits exactly when either does
# HTTP-FORM-2
law any_step:
  for hit: Bool
  for rest: Unit -> Bool
  {Form.any.step(hit, rest) == Bool.or(hit, rest(Unit{})) : Bool}

# LAW: no octets hold a pattern exactly when the pattern is empty
# HTTP-FORM-2
law has_nil:
  for +pat: List<&2, U32>
  {Form.octets.has([], pat) == Form.octets.starts([], pat) : Bool}

# LAW: octets hold a pattern exactly when they open with it or their rest
# holds it
# HTTP-FORM-2
law has_cons:
  for +x: U32
  for +t: List<&2, U32>
  for +pat: List<&2, U32>
  {Form.octets.has(x <> t, pat)
    == Bool.or(Form.octets.starts(x <> t, pat), Form.octets.has(t, pat))
    : Bool}

# LAW: every octets open with the empty pattern
# HTTP-FORM-2
law starts_done:
  for xs: List<&2, U32>
  {Form.octets.starts(xs, []) == True{} : Bool}

# LAW: no octets open with a pattern that is not empty
# HTTP-FORM-2
law starts_short:
  for p: U32
  for q: List<&2, U32>
  {Form.octets.starts([], p <> q) == False{} : Bool}

# LAW: octets open with a pattern exactly when their first octets are equal
# and the rest opens with the pattern's rest
# HTTP-FORM-2
law starts_cons:
  for x: U32
  for t: List<&2, U32>
  for p: U32
  for q: List<&2, U32>
  {Form.octets.starts(x <> t, p <> q)
    == Bool.and(U32.is_eq(x, p), Form.octets.starts(t, q)) : Bool}

# LAW: a field's content is its value's UTF-8 octets
# HTTP-FORM-2
# HTTP-FORM-3
law content_field:
  for name: String
  for value: String
  for rest: List<&2, U32>
  {Form.form.content(Form.Field{name, value}, rest)
    == Form.octets.onto(value, rest) : List<&2, U32>}

# LAW: a file's content is its bytes, unchanged
# HTTP-FORM-2
# HTTP-FORM-3
law content_file:
  for name: String
  for filename: String
  for ctype: String
  for bytes: List<&2, U32>
  for rest: List<&2, U32>
  {Form.form.content(Form.File{name, filename, ctype, bytes}, rest)
    == List.append(&2, U32, bytes, rest) : List<&2, U32>}

# LAW: no parts hold a bad content type
# HTTP-FORM-2
law badtype_nil:
  for ps: List<&2, Form.Part>
  for e: {[] == ps : List<&2, Form.Part>}
  {Form.form.badtype(ps) == False{} : Bool}

# LAW: a list of parts holds a bad content type exactly when its first part
# or its rest does
# HTTP-FORM-2
law badtype_cons:
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.badtype(p <> t)
    == Bool.or(Form.form.badtype.one(p), Form.form.badtype(t)) : Bool}

# LAW: a field part has no content type to be bad
# HTTP-FORM-2
law badtype_field:
  for name: String
  for value: String
  {Form.form.badtype.one(Form.Field{name, value}) == False{} : Bool}

# LAW: a file part's content type is bad exactly when it holds a CR or an LF
# HTTP-FORM-2
law badtype_file:
  for name: String
  for filename: String
  for +ctype: String
  for bytes: List<&2, U32>
  {Form.form.badtype.one(Form.File{name, filename, ctype, bytes})
    == Bool.or(String.contains(ctype, "\r"), String.contains(ctype, "\n"))
    : Bool}

# LAW (RFC 2046 §5.1.1): after the last part comes the close delimiter
# HTTP-FORM-3
law parts_nil:
  for +b: String
  {Form.form.parts(b, []) == Form.octets.onto("--" ++ b ++ "--\r\n", [])
    : List<&2, U32>}

# LAW: the parts are written in order, each in front of the rest
# HTTP-FORM-3
law parts_cons:
  for +b: String
  for p: Form.Part
  for t: List<&2, Form.Part>
  {Form.form.parts(b, p <> t) == Form.form.part(b, p, Form.form.parts(b, t))
    : List<&2, U32>}

# LAW (RFC 7578 §4.1): a part is the delimiter line, its header lines, a blank
# line, its content and a CRLF
# HTTP-FORM-3
law part:
  for +b: String
  for +p: Form.Part
  for rest: List<&2, U32>
  {Form.form.part(b, p, rest)
    == Form.octets.onto("--" ++ b ++ "\r\n" ++ Form.form.head(p) ++ "\r\n",
      Form.form.content(p, Form.octets.onto("\r\n", rest))) : List<&2, U32>}

# LAW: the empty string writes no octets
# HTTP-FORM-3
law onto_nil:
  for rest: List<&2, U32>
  {Form.octets.onto("", rest) == rest : List<&2, U32>}

# LAW (RFC 3629 §3): a string is written as its first character's UTF-8
# octets, then the rest's
# HTTP-FORM-3
law onto_cons:
  for +c: U32
  for t: String
  for rest: List<&2, U32>
  {Form.octets.onto(SCon{Chr{c}, t}, rest)
    == List.append(&2, U32, Pct.utf8(c), Form.octets.onto(t, rest))
    : List<&2, U32>}

# LAW: form_field makes a field part
# HTTP-FORM-4
law field_is:
  for name: String
  for value: String
  {Form.form.field(name, value) == Form.Field{name, value} : Form.Part}

# LAW: form_file makes a file part
# HTTP-FORM-4
law file_is:
  for name: String
  for filename: String
  for ctype: String
  for bytes: List<&2, U32>
  {Form.form.file(name, filename, ctype, bytes)
    == Form.File{name, filename, ctype, bytes} : Form.Part}

# LAW (RFC 7578 §4.2): a field part's header is its Content-Disposition line
# HTTP-FORM-4
law head_field:
  for name: String
  for value: String
  {Form.form.head(Form.Field{name, value})
    == Form.form.disposition(name) ++ "\r\n" : String}

# LAW (RFC 7578 §4.2, §4.4): a file part's header is its Content-Disposition
# line with the filename, then its Content-Type line
# HTTP-FORM-4
law head_file:
  for name: String
  for filename: String
  for ctype: String
  for bytes: List<&2, U32>
  {Form.form.head(Form.File{name, filename, ctype, bytes})
    == Form.form.disposition(name) ++ "; filename=\"" ++ Form.form.quote(filename)
      ++ "\"\r\n" ++ "Content-Type: " ++ ctype ++ "\r\n" : String}

# LAW (RFC 7578 §4.2): the disposition names the part, quoted
# HTTP-FORM-4
law disposition:
  for name: String
  {Form.form.disposition(name)
    == "Content-Disposition: form-data; name=\"" ++ Form.form.quote(name)
      ++ "\"" : String}

# LAW: the empty name is written as the empty string
# HTTP-FORM-5
law fq_nil:
  for s: String
  for e: {SNil{} == s : String}
  {Form.form.quote(s) == "" : String}

# LAW: a name is written one character at a time, the first character's
# writing followed by the rest's
# HTTP-FORM-5
law fq_cons:
  for +c: U32
  for t: String
  {Form.form.quote(SCon{Chr{c}, t}) == Form.form.one(c, Form.form.quote(t))
    : String}

# LAW (RFC 7578 §4.2): `"` is written as %22
# HTTP-FORM-5
law fq_dq:
  for rest: String
  {Form.form.one(34, rest) == "%22" ++ rest : String}

# LAW (RFC 7578 §4.2): CR is written as %0D
# HTTP-FORM-5
law fq_cr:
  for rest: String
  {Form.form.one(13, rest) == "%0D" ++ rest : String}

# LAW (RFC 7578 §4.2): LF is written as %0A
# HTTP-FORM-5
law fq_lf:
  for rest: String
  {Form.form.one(10, rest) == "%0A" ++ rest : String}

# LAW: every other character is written as itself
# HTTP-FORM-5
law fq_other:
  for +c: U32
  for e1: {False{} == U32.is_eq(c, 34) : Bool}
  for e2: {False{} == U32.is_eq(c, 13) : Bool}
  for e3: {False{} == U32.is_eq(c, 10) : Bool}
  for rest: String
  {Form.form.one(c, rest) == SCon{Chr{c}, rest} : String}
