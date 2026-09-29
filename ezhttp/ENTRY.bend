# ezhttp: laws on the entry (main.bend) and client.bend. Their re-exports and
# helpers are the pure definitions LAWS.bend states laws for.
#
# main.bend and client.bend reach the wire effect (user foreign code), so from
# bend 2.0.32 no file importing them can print ALL PROOFS CHECK: the verdict
# covers every def of every import. `bend ezhttp/ENTRY.bend` must print
# SOME PROOFS FAIL with the foreign-code list as its only error (the wire
# effect and the defs that reach it); the flake's proofs check holds it to that.
import Base
import ./http.bend as Http
import ./url.bend as Url
import ./body.bend as Body
import ./auth.bend as Auth
import ./cookie.bend as Cookie
import ./cache.bend as Cache
import ./cors.bend as Cors
import ./client.bend as Client
import ./main.bend as Ez

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

# LAW: cors_reply is the CORS helper
law cors_reply_is_on:
  for cfg: Cors.Cfg
  for req: Http.Request
  for reply: Http.Reply
  {Ez.cors_reply(cfg, req, reply) == Cors.cors.on(cfg, req, reply)
    : Http.Reply}

# --- fills ---

# parse_url_is_url_parse holds by unfolding the re-export
def parse_url_is_url_parse(_url):
  {==}

# parse_response_is_http_parse holds by unfolding the re-export
def parse_response_is_http_parse(_raw):
  {==}

# parse_request_is_ask holds by unfolding the re-export
def parse_request_is_ask(_raw):
  {==}

# format_response_is_respond holds by unfolding the re-export
def format_response_is_respond(_status, _hs, _body):
  {==}

# empty_body_is_empty holds by unfolding the re-export
def empty_body_is_empty():
  {==}

# text_body_is_text holds by unfolding the re-export
def text_body_is_text(_s):
  {==}

# octets_body_is_octets holds by unfolding the re-export
def octets_body_is_octets(_bs):
  {==}

# bearer_is_authorization holds by unfolding the re-export
def bearer_is_authorization(_token):
  {==}

# bearer_is_client_bearer holds by unfolding the re-export
def bearer_is_client_bearer(_token):
  {==}

# encode_is_body_encode holds by unfolding the re-export
def encode_is_body_encode(_s):
  {==}

# decode_is_body_decode holds by unfolding the re-export
def decode_is_body_decode(_s):
  {==}

# basic_user_pass holds by unfolding the re-export
def basic_user_pass():
  {==}

# basic_is_client_basic holds by unfolding the re-export
def basic_is_client_basic(_user, _password):
  {==}

# set_cookie_is_cookie_set holds by unfolding the re-export
def set_cookie_is_cookie_set(_c):
  {==}

# parse_cookie_is_parse holds by unfolding the re-export
def parse_cookie_is_parse(_line):
  {==}

# cookie_header_is_request holds by unfolding the re-export
def cookie_header_is_request(_cs):
  {==}

# cache_control_is_parse holds by unfolding the re-export
def cache_control_is_parse(_value):
  {==}

# fresh_is_cache_fresh holds by unfolding the re-export
def fresh_is_cache_fresh(_value, _age):
  {==}

# cors_reply_is_on holds by unfolding the re-export
def cors_reply_is_on(_cfg, _req, _reply):
  {==}
