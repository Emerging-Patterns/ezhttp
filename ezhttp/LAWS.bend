# ezhttp: the laws. Closed equalities for URL parsing (RFC 3986), HTTP/1.1
# message framing (RFC 9112), and HTTP semantics used by the client
# (RFC 9110). PROOF.bend fills them. `bend ezhttp/PROOF.bend` is the gate.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body
import ./client.bend as Client
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
