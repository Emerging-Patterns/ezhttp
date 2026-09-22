# ezhttp: the laws. Closed equalities for URL parsing (RFC 3986), HTTP/1.1
# message framing (RFC 9112), HTTP semantics (RFC 9110), TLS selection
# (RFC 2818), Basic and Bearer credentials (RFC 7617, RFC 4648, RFC 6750),
# cookies (RFC 6265), caching directives (RFC 9111), and Fetch CORS.
# PROOF.bend fills them. `bend ezhttp/PROOF.bend` is the gate.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body
import ./client.bend as Client
import ./wire.bend as Wire
import ./b64.bend as B64
import ./cookie.bend as Cookie
import ./cache.bend as Cache
import ./cors.bend as Cors
import ./main.bend as Ez

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

# LAW: parse_url is Url.parse
law parse_url_is_url_parse:
  for url: String
  {Ez.parse_url(url) == Url.parse(url) : Url.Loc}

# LAW: parse_response is Http.parse
law parse_response_is_http_parse:
  for raw: String
  {Ez.parse_response(raw) == Http.parse(raw) : Http.Reply}

# LAW: parse_request is Http.ask
law parse_request_is_ask:
  for raw: String
  {Ez.parse_request(raw) == Http.ask(raw) : Http.Request}

# LAW: format_response is Http.respond
law format_response_is_respond:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {Ez.format_response(status, hs, body) == Http.respond(status, hs, body)
    : String}

# LAW: empty_body is empty
law empty_body_is_empty:
  {Ez.empty_body() == Body.body.empty() : Body.Body}

# LAW: text_body wraps Text
law text_body_is_text:
  for s: String
  {Ez.text_body(s) == Body.body.text(s) : Body.Body}

# LAW: octets_body wraps Octets
law octets_body_is_octets:
  for bs: List<&2, U32>
  {Ez.octets_body(bs) == Body.body.octets(bs) : Body.Body}

# LAW: bearer builds Authorization: Bearer …
law bearer_is_authorization:
  for token: String
  {Ez.bearer(token) == Http.H{"Authorization", "Bearer " ++ token}
    : Http.Header}

# LAW: bearer is the client helper (reaches client.bend for type coverage)
law bearer_is_client_bearer:
  for token: String
  {Ez.bearer(token) == Client.client.bearer(token) : Http.Header}

# LAW: encode is Body.body.encode (identity of the wrapper)
law encode_is_body_encode:
  for +s: String
  {Ez.encode(String, x => x, s) == Body.body.encode(String, x => x, s)
    : Body.Body}

# LAW: decode is Body.body.decode
law decode_is_body_decode:
  for +s: String
  {Ez.decode(String, x => Some{x}, s)
    == Body.body.decode(String, x => Some{x}, s) : Maybe<&2, String>}

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
  {Wire.wire.spec(True{}, "example.com", 443, "GET / HTTP/1.1\r\n\r\n")
    == "tls\nexample.com\n443\nGET / HTTP/1.1\r\n\r\n" : String}

# LAW: a cleartext exchange is labeled tcp
law wire_http_is_tcp:
  {Wire.wire.spec(False{}, "example.com", 80, "GET / HTTP/1.1\r\n\r\n")
    == "tcp\nexample.com\n80\nGET / HTTP/1.1\r\n\r\n" : String}

# --- RFC 9112 request and response writers ---

# LAW (RFC 9110 §7.2, RFC 9112 §3, §9.6): every client request names its Host
# and asks for Connection: close
law request_frames_host_and_close:
  for +method: String
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
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

# LAW (RFC 9112 §4, §9.6): a response status-line is HTTP/1.1 plus the
# reason-phrase, and the connection closes
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
  {Ez.basic("user", "pass")
    == Http.H{"Authorization", "Basic dXNlcjpwYXNz"} : Http.Header}

# LAW: basic is the client helper
law basic_is_client_basic:
  for user: String
  for password: String
  {Ez.basic(user, password) == Client.client.basic(user, password)
    : Http.Header}

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

# LAW: set_cookie is the Set-Cookie serializer
law set_cookie_is_cookie_set:
  for c: Cookie.Cookie
  {Ez.set_cookie(c) == Cookie.cookie.set(c) : Http.Header}

# LAW: parse_cookie is the Set-Cookie parser
law parse_cookie_is_parse:
  for line: String
  {Ez.parse_cookie(line) == Cookie.cookie.parse(line)
    : Maybe<&2, Cookie.Cookie>}

# LAW: cookie_header is the Cookie request header
law cookie_header_is_request:
  for cs: List<&2, Cookie.Cookie>
  {Ez.cookie_header(cs) == Cookie.cookie.request(cs) : Http.Header}

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

# LAW: cache_control is the Cache-Control parser
law cache_control_is_parse:
  for value: String
  {Ez.cache_control(value) == Cache.cache.parse(value) : Cache.Cc}

# LAW: fresh is freshness of the parsed directives
law fresh_is_cache_fresh:
  for value: String
  for age: Nat
  {Ez.fresh(value, age)
    == Cache.cache.fresh(Cache.cache.parse(value), age) : Bool}

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

# LAW: cors_reply is the CORS helper
law cors_reply_is_on:
  for cfg: Cors.Cfg
  for req: Http.Request
  for reply: Http.Reply
  {Ez.cors_reply(cfg, req, reply) == Cors.cors.on(cfg, req, reply)
    : Http.Reply}

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
