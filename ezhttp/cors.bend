# ezhttp/cors: Fetch CORS response headers for a simple request and an OPTIONS
# preflight. Origins are reflected, or `*`, and credentials never pair with `*`.
# See https://fetch.spec.whatwg.org/#cors-protocol.
import Base
import ./http.bend as Http

# allow-list for a server. `origins` of `["*"]` allows any origin.
type Cfg is Data:
  Cfg{
    origins: List<&2, String>
    methods: List<&2, String>
    headers: List<&2, String>
    credentials: Bool
    max_age: String
    expose: List<&2, String>
  }

# whether `*` is one of the allowed origins
def cors.star.step(hit: Bool, rest: Unit -> Bool) -> Bool:
  match hit:
    case True{}:
      True{}
    case False{}:
      rest(Unit{})

# walk origins for `*`
def cors.star(os: List<&2, String>) -> Bool:
  match os:
    case []:
      False{}
    case h <> t:
      cors.star.step(String.eq(h, "*"), _u => cors.star(t))

# case-sensitive membership
def cors.hit.step(hit: Bool, rest: Unit -> Bool) -> Bool:
  match hit:
    case True{}:
      True{}
    case False{}:
      rest(Unit{})

# whether the needle is in the list
def cors.hit(+needle: String, xs: List<&2, String>) -> Bool:
  match xs:
    case []:
      False{}
    case h <> t:
      cors.hit.step(String.eq(h, needle), _u => cors.hit(needle, t))

# lowercase a list of names
def cors.lower(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case []:
      []
    case h <> t:
      String.to_lower(h) <> cors.lower(t)

# case-insensitive membership (header names, RFC 9110 §5.1)
def cors.hit_ci(+needle: String, xs: List<&2, String>) -> Bool:
  cors.hit(String.to_lower(needle), cors.lower(xs))

# `*`, or an explicit origin
def cors.allowed(+os: List<&2, String>, origin: String) -> Bool:
  Bool.or(cors.star(os), cors.hit(origin, os))

# `*` when every origin is allowed and credentials are off; else the origin
def cors.acao.star(origin: String, star: Bool) -> String:
  match star:
    case True{}:
      "*"
    case False{}:
      origin

# credentials always reflect the origin (Fetch: `*` cannot be used)
def cors.acao.cred(+os: List<&2, String>, origin: String, credentials: Bool)
  -> String:
  match credentials:
    case True{}:
      origin
    case False{}:
      cors.acao.star(origin, cors.star(os))

# empty when the origin is not allowed
def cors.acao.ok(+os: List<&2, String>, credentials: Bool, origin: String,
  ok: Bool) -> String:
  match ok:
    case False{}:
      ""
    case True{}:
      cors.acao.cred(os, origin, credentials)

# Access-Control-Allow-Origin value, or "" when the origin is refused
def cors.acao(+os: List<&2, String>, credentials: Bool, +origin: String) -> String:
  cors.acao.ok(os, credentials, origin, cors.allowed(os, origin))

# true when ACAO is a specific origin and Vary: Origin should be set
def cors.vary(+acao: String) -> Bool:
  Bool.and(Bool.not(String.eq(acao, "*")), Bool.not(String.eq(acao, "")))

# every requested header name is allowed. Empty means none were requested.
def cors.names.step(ok: Bool, rest: Unit -> Bool) -> Bool:
  match ok:
    case True{}:
      rest(Unit{})
    case False{}:
      False{}

# requested header names against the allow list
def cors.names(ps: List<&2, String>, +allow: List<&2, String>) -> Bool:
  match ps:
    case []:
      True{}
    case h <> t:
      cors.names.step(cors.hit_ci(String.trim(h), allow), _u => cors.names(t, allow))

# an empty request-header list asks for nothing
def cors.headers_empty(+requested: String, +allow: List<&2, String>, empty: Bool)
  -> Bool:
  match empty:
    case True{}:
      True{}
    case False{}:
      cors.names(String.split(requested, ','), allow)

# Access-Control-Request-Headers, comma-separated
def cors.headers_ok(+requested: String, +allow: List<&2, String>) -> Bool:
  cors.headers_empty(requested, allow, String.eq(requested, ""))

# join with ", "
def cors.join(xs: List<&2, String>) -> String:
  String.join(xs, ", ")

# append Vary when the origin is reflected
def cors.vary_on(hs: List<&2, Http.Header>, _acao: String, vary: Bool)
  -> List<&2, Http.Header>:
  match vary:
    case False{}:
      hs
    case True{}:
      Http.H{"Vary", "Origin"} <> hs

# append credentials when they are allowed
def cors.cred_on(hs: List<&2, Http.Header>, credentials: Bool)
  -> List<&2, Http.Header>:
  match credentials:
    case False{}:
      hs
    case True{}:
      Http.H{"Access-Control-Allow-Credentials", "true"} <> hs

# preflight response headers
def cors.preflight_hs(+acao: String, methods: List<&2, String>,
  headers: List<&2, String>, credentials: Bool, max_age: String)
  -> List<&2, Http.Header>:
  cors.cred_on(cors.vary_on([
    Http.H{"Access-Control-Allow-Origin", acao},
    Http.H{"Access-Control-Allow-Methods", cors.join(methods)},
    Http.H{"Access-Control-Allow-Headers", cors.join(headers)},
    Http.H{"Access-Control-Max-Age", max_age}
  ], acao, cors.vary(acao)), credentials)

# 400 when a requested header is not allowed; otherwise 200
def cors.preflight.headers(acao: String, methods: List<&2, String>,
  headers: List<&2, String>, credentials: Bool, max_age: String,
  _req: String, ok: Bool) -> Http.Reply:
  match ok:
    case False{}:
      Http.Reply{400, [], ""}
    case True{}:
      Http.Reply{200, cors.preflight_hs(acao, methods, headers, credentials,
        max_age), ""}

# 400 when the method is not allowed
def cors.preflight.method(acao: String, methods: List<&2, String>,
  +headers: List<&2, String>, credentials: Bool, max_age: String,
  +req_headers: String, method: String, ok: Bool) -> Http.Reply:
  match ok:
    case False{}:
      Http.Reply{400, [], ""}
    case True{}:
      cors.preflight.headers(acao, methods, headers, credentials, max_age,
        req_headers, cors.headers_ok(req_headers, headers))

# skip the method check when the origin was refused
def cors.preflight.denied(acao: String, +methods: List<&2, String>,
  headers: List<&2, String>, credentials: Bool, max_age: String,
  req_headers: String, +method: String, denied: Bool) -> Http.Reply:
  match denied:
    case True{}:
      Http.Reply{400, [], ""}
    case False{}:
      cors.preflight.method(acao, methods, headers, credentials, max_age,
        req_headers, method, cors.hit(method, methods))

# OPTIONS preflight (Fetch CORS). Refused origins and methods are 400.
def cors.preflight(cfg: Cfg, origin: String, method: String, req_headers: String)
  -> Http.Reply:
  match cfg:
    case Cfg{+origins, methods, headers, +credentials, max_age, expose}:
      +acao = cors.acao(origins, credentials, origin)
      cors.preflight.denied(acao, methods, headers, credentials, max_age,
        req_headers, method, String.eq(acao, ""))

# Access-Control-Expose-Headers when the list is not empty
def cors.expose_of(hs: List<&2, Http.Header>, expose: List<&2, String>,
  empty: Bool) -> List<&2, Http.Header>:
  match empty:
    case True{}:
      hs
    case False{}:
      Http.H{"Access-Control-Expose-Headers", cors.join(expose)} <> hs

# Access-Control-Expose-Headers when the list is not empty
def cors.expose_on(hs: List<&2, Http.Header>, +expose: List<&2, String>)
  -> List<&2, Http.Header>:
  cors.expose_of(hs, expose, List.is_empty(&2, String, expose))

# simple-response CORS headers (ACAO, optional credentials, expose, vary)
def cors.simple_hs(+acao: String, credentials: Bool, expose: List<&2, String>)
  -> List<&2, Http.Header>:
  cors.cred_on(cors.vary_on(cors.expose_on([
    Http.H{"Access-Control-Allow-Origin", acao}
  ], expose), acao, cors.vary(acao)), credentials)

# leave a reply alone when there is nothing to add
def cors.simple.skip(add: Bool, reply: Http.Reply, hs: List<&2, Http.Header>)
  -> Http.Reply:
  match add reply:
    case False{} r:
      r
    case True{} Http.Torn{why}:
      Http.Torn{why}
    case True{} Http.Reply{status, headers, body}:
      Http.Reply{status, List.append(&2, Http.Header, hs, headers), body}

# append CORS headers when the origin is allowed
def cors.simple.add(reply: Http.Reply, acao: String, credentials: Bool,
  expose: List<&2, String>, add: Bool) -> Http.Reply:
  cors.simple.skip(add, reply, cors.simple_hs(acao, credentials, expose))

# a non-preflight response. A missing or refused origin is unchanged.
def cors.simple(cfg: Cfg, origin: String, reply: Http.Reply) -> Http.Reply:
  match cfg:
    case Cfg{+origins, methods, headers, +credentials, max_age, expose}:
      +acao = cors.acao(origins, credentials, origin)
      cors.simple.add(reply, acao, credentials, expose,
        Bool.not(String.eq(acao, "")))

# Origin request header
def cors.origin(origin: String) -> Http.Header:
  Http.H{"Origin", origin}

# Access-Control-Request-Method
def cors.request_method(method: String) -> Http.Header:
  Http.H{"Access-Control-Request-Method", method}

# Access-Control-Request-Headers
def cors.request_headers(names: String) -> Http.Header:
  Http.H{"Access-Control-Request-Headers", names}

# OPTIONS with Access-Control-Request-Method is a preflight
def cors.is_preflight.method(method: String, asked: String) -> Bool:
  Bool.and(String.eq(method, "OPTIONS"), Bool.not(String.eq(asked, "")))

# whether this request is a CORS preflight
def cors.is_preflight(req: Http.Request) -> Bool:
  match req:
    case Http.Bad{why}:
      False{}
    case Http.Request{method, target, headers, body}:
      cors.is_preflight.method(method,
        Http.headers.find(headers, "access-control-request-method"))

# preflight from the request's CORS headers
def cors.preflight_req(cfg: Cfg, req: Http.Request) -> Http.Reply:
  match req:
    case Http.Bad{why}:
      Http.Reply{400, [], why}
    case Http.Request{method, target, +headers, body}:
      cors.preflight(cfg, Http.headers.find(headers, "origin"),
        Http.headers.find(headers, "access-control-request-method"),
        Http.headers.find(headers, "access-control-request-headers"))

# simple CORS from the request Origin
def cors.simple_req(cfg: Cfg, req: Http.Request, reply: Http.Reply) -> Http.Reply:
  match req:
    case Http.Bad{why}:
      reply
    case Http.Request{method, target, headers, body}:
      cors.simple(cfg, Http.headers.find(headers, "origin"), reply)

# preflight, or CORS headers on the handler reply
def cors.route(cfg: Cfg, req: Http.Request, +reply: Http.Reply, pre: Bool)
  -> Http.Reply:
  match pre:
    case True{}:
      cors.preflight_req(cfg, req)
    case False{}:
      cors.simple_req(cfg, req, reply)

# answer a request: preflight or simple CORS on top of `reply`
def cors.on(cfg: Cfg, +req: Http.Request, reply: Http.Reply) -> Http.Reply:
  cors.route(cfg, req, reply, cors.is_preflight(req))
