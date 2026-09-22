# ezhttp/cookie: Set-Cookie and Cookie (RFC 6265 §§4–5). A thin jar: parse
# attributes, serialize the request header, and domain/path/secure matching.
# Expires is stored, not evaluated against a clock. SameSite is stored; there
# is no browsing context to suppress cross-site sends.
import Base
import ./http.bend as Http

# one cookie. host_only means the Domain attribute was absent (exact host).
type Cookie is Data:
  Cookie{
    name: String
    value: String
    expires: String
    max_age: String
    domain: String
    path: String
    secure: Bool
    http_only: Bool
    same_site: String
    host_only: Bool
  }

# a session cookie with no attributes yet
def cookie.new(name: String, value: String) -> Cookie:
  Cookie{name, value, "", "", "", "", False{}, False{}, "", True{}}

# replace Expires
def cookie.expires(c: Cookie, when: String) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, when, max_age, domain, path, secure, http_only,
        same_site, host_only}

# replace Max-Age
def cookie.age(c: Cookie, age: String) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, age, domain, path, secure, http_only,
        same_site, host_only}

# replace Domain and clear host-only
def cookie.domain(c: Cookie, host: String) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, max_age, host, path, secure, http_only,
        same_site, False{}}

# replace Path
def cookie.dir(c: Cookie, dir: String) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, max_age, domain, dir, secure, http_only,
        same_site, host_only}

# set the Secure flag
def cookie.secure_on(c: Cookie) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, max_age, domain, path, True{}, http_only,
        same_site, host_only}

# set the HttpOnly flag
def cookie.http_on(c: Cookie) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, max_age, domain, path, secure, True{},
        same_site, host_only}

# replace SameSite
def cookie.site_set(c: Cookie, site: String) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      Cookie{name, value, expires, max_age, domain, path, secure, http_only,
        site, host_only}

# None, or unrecognized
def cookie.site.none(_low: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "None"
    case False{}:
      ""

# Strict, or continue
def cookie.site.strict(+low: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "Strict"
    case False{}:
      cookie.site.none(low, String.eq(low, "none"))

# Lax / Strict / None, canonical spelling (RFC 6265bis SameSite)
def cookie.site.lax(+low: String, hit: Bool) -> String:
  match hit:
    case True{}:
      "Lax"
    case False{}:
      cookie.site.strict(low, String.eq(low, "strict"))

# canonicalize a SameSite value; anything else is dropped
def cookie.site(+raw: String) -> String:
  +low = String.to_lower(raw)
  cookie.site.lax(low, String.eq(low, "lax"))

# keep a numeric Max-Age, ignore the attribute when it is not digits
def cookie.age_ok(c: Cookie, +raw: String, m: Maybe<&2, Nat>) -> Cookie:
  match m:
    case None{}:
      c
    case Some{n}:
      cookie.age(c, raw)

# HttpOnly flag, or leave the cookie alone
def cookie.flag.http(c: Cookie, _name: String, hit: Bool) -> Cookie:
  match hit:
    case True{}:
      cookie.http_on(c)
    case False{}:
      c

# Secure flag, else HttpOnly
def cookie.flag.secure(c: Cookie, +name: String, hit: Bool) -> Cookie:
  match hit:
    case True{}:
      cookie.secure_on(c)
    case False{}:
      cookie.flag.http(c, name, String.eq(name, "httponly"))

# a flag attribute (no equals sign)
def cookie.flag(c: Cookie, +name: String) -> Cookie:
  cookie.flag.secure(c, name, String.eq(name, "secure"))

# SameSite, or an unrecognized attribute
def cookie.named.site(c: Cookie, _name: String, value: String, hit: Bool)
  -> Cookie:
  match hit:
    case True{}:
      cookie.site_set(c, cookie.site(value))
    case False{}:
      c

# Path
def cookie.named.path(c: Cookie, +name: String, +value: String, hit: Bool)
  -> Cookie:
  match hit:
    case True{}:
      cookie.dir(c, value)
    case False{}:
      cookie.named.site(c, name, value, String.eq(name, "samesite"))

# Domain, stored lowercase
def cookie.named.domain(c: Cookie, +name: String, +value: String, hit: Bool)
  -> Cookie:
  match hit:
    case True{}:
      cookie.domain(c, String.to_lower(value))
    case False{}:
      cookie.named.path(c, name, value, String.eq(name, "path"))

# Max-Age
def cookie.named.age(c: Cookie, +name: String, +value: String, hit: Bool)
  -> Cookie:
  match hit:
    case True{}:
      cookie.age_ok(c, value, Http.digits.read(value))
    case False{}:
      cookie.named.domain(c, name, value, String.eq(name, "domain"))

# Expires, stored as the HTTP-date text
def cookie.named.expires(c: Cookie, +name: String, +value: String, hit: Bool)
  -> Cookie:
  match hit:
    case True{}:
      cookie.expires(c, value)
    case False{}:
      cookie.named.age(c, name, value, String.eq(name, "max-age"))

# one name=value attribute
def cookie.named(c: Cookie, +name: String, +value: String) -> Cookie:
  cookie.named.expires(c, name, value, String.eq(name, "expires"))

# one attribute piece, flag or name=value
def cookie.apply.cut(c: Cookie, +piece: String, cut: Http.Cut) -> Cookie:
  match cut:
    case Http.NoCut{}:
      cookie.flag(c, String.to_lower(String.trim(piece)))
    case Http.Cut{before, after}:
      cookie.named(c, String.to_lower(String.trim(before)), String.trim(after))

# one semicolon-separated attribute
def cookie.apply(c: Cookie, +piece: String) -> Cookie:
  cookie.apply.cut(c, piece, Http.divide(piece, "="))

# walk attributes. The list is the shrinking argument.
def cookie.fold(ps: List<&2, String>, c: Cookie) -> Cookie:
  match ps:
    case []:
      c
    case h <> t:
      cookie.fold(t, cookie.apply(c, String.trim(h)))

# reject an empty name (RFC 6265 §4.1.1)
def cookie.from.name(+name: String, value: String, attrs: List<&2, String>,
  empty: Bool) -> Maybe<&2, Cookie>:
  match empty:
    case True{}:
      None{}
    case False{}:
      Some{cookie.fold(attrs, cookie.new(name, value))}

# the name=value pair, then the attribute list
def cookie.from(_pair: String, attrs: List<&2, String>, cut: Http.Cut)
  -> Maybe<&2, Cookie>:
  match cut:
    case Http.NoCut{}:
      None{}
    case Http.Cut{before, after}:
      +name = String.trim(before)
      cookie.from.name(name, String.trim(after), attrs, String.eq(name, ""))

# Set-Cookie split on `;`
def cookie.parse.parts(ps: List<&2, String>) -> Maybe<&2, Cookie>:
  match ps:
    case []:
      None{}
    case h <> t:
      +pair = String.trim(h)
      cookie.from(pair, t, Http.divide(pair, "="))

# parse one Set-Cookie line (the field value, not the header name)
def cookie.parse(line: String) -> Maybe<&2, Cookie>:
  cookie.parse.parts(String.split(line, ';'))

# `; Name=value` when value is present
def cookie.opt.of(prefix: String, value: String, empty: Bool) -> String:
  match empty:
    case True{}:
      ""
    case False{}:
      prefix ++ value

# an optional attribute clause
def cookie.opt(prefix: String, +value: String) -> String:
  cookie.opt.of(prefix, value, String.eq(value, ""))

# `; Domain=…` only when a Domain attribute was set
def cookie.domain_text(domain: String, host_only: Bool) -> String:
  match host_only:
    case True{}:
      ""
    case False{}:
      cookie.opt("; Domain=", domain)

# `; Secure` / `; HttpOnly` when the flag is set
def cookie.mark(label: String, on: Bool) -> String:
  match on:
    case False{}:
      ""
    case True{}:
      "; " ++ label

# Set-Cookie field value (RFC 6265 §4.1.1)
def cookie.line(c: Cookie) -> String:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      name ++ "=" ++ value
        ++ cookie.opt("; Expires=", expires)
        ++ cookie.opt("; Max-Age=", max_age)
        ++ cookie.domain_text(domain, host_only)
        ++ cookie.opt("; Path=", path)
        ++ cookie.mark("Secure", secure)
        ++ cookie.mark("HttpOnly", http_only)
        ++ cookie.opt("; SameSite=", same_site)

# a Set-Cookie header
def cookie.set(c: Cookie) -> Http.Header:
  Http.H{"Set-Cookie", cookie.line(c)}

# keep name=value when the name is not empty
def cookie.pairs.keep(name: String, value: String, empty: Bool,
  rest: Unit -> List<&2, String>) -> List<&2, String>:
  match empty:
    case True{}:
      rest(Unit{})
    case False{}:
      (name ++ "=" ++ value) <> rest(Unit{})

# one cookie as a request pair, dropped when the name is empty
def cookie.pairs.one(c: Cookie, rest: Unit -> List<&2, String>)
  -> List<&2, String>:
  match c:
    case Cookie{+name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      cookie.pairs.keep(name, value, String.eq(name, ""), rest)

# name=value pieces, empty names removed
def cookie.pairs(cs: List<&2, Cookie>) -> List<&2, String>:
  match cs:
    case []:
      []
    case h <> t:
      cookie.pairs.one(h, _u => cookie.pairs(t))

# Cookie field value: pairs joined by `; ` (RFC 6265 §5.4)
def cookie.join(cs: List<&2, Cookie>) -> String:
  String.join(cookie.pairs(cs), "; ")

# a Cookie request header
def cookie.request(cs: List<&2, Cookie>) -> Http.Header:
  Http.H{"Cookie", cookie.join(cs)}

# count `/` in a path
def cookie.slashes.ch(slash: Bool, rest: Unit -> Nat) -> Nat:
  match slash:
    case False{}:
      rest(Unit{})
    case True{}:
      Nat.add(1n, rest(Unit{}))

# how many slashes a path holds
def cookie.slashes(p: String) -> Nat:
  match p:
    case SNil{}:
      0n
    case SCon{h, t}:
      cookie.slashes.ch(Char.is_eq(h, '/'), _u => cookie.slashes(t))

# drop the reversed prefix through the first slash
def cookie.skip.ch(hit: Bool, +tail: String, rest: Unit -> String) -> String:
  match hit:
    case True{}:
      tail
    case False{}:
      rest(Unit{})

# reversed path with the last segment removed
def cookie.skip(p: String) -> String:
  match p:
    case SNil{}:
      ""
    case SCon{h, +t}:
      cookie.skip.ch(Char.is_eq(h, '/'), t, _u => cookie.skip(t))

# characters before the right-most slash
def cookie.before(p: String) -> String:
  String.reverse(cookie.skip(String.reverse(p)))

# `/` when the path has fewer than two slashes, else the directory prefix
def cookie.default_of(+p: String, few: Bool) -> String:
  match few:
    case True{}:
      "/"
    case False{}:
      cookie.before(p)

# default-path (RFC 6265 §5.1.4)
def cookie.default_path(+p: String) -> String:
  cookie.default_of(p, Nat.is_lt(cookie.slashes(p), 2n))

# host-only cookies take the response host; Domain stays as parsed
def cookie.fill_domain(domain: String, host_only: Bool, host: String) -> String:
  match host_only:
    case True{}:
      host
    case False{}:
      domain

# an absent Path becomes default-path
def cookie.fill_path.of(path: String, req: String, empty: Bool) -> String:
  match empty:
    case True{}:
      cookie.default_path(req)
    case False{}:
      path

# an absent Path becomes default-path
def cookie.fill_path(+path: String, req: String) -> String:
  cookie.fill_path.of(path, req, String.eq(path, ""))

# store the response host on a host-only cookie and fill default-path
def cookie.receive(host: String, req_path: String, c: Cookie) -> Cookie:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, +host_only}:
      Cookie{name, value, expires, max_age,
        cookie.fill_domain(domain, host_only, String.to_lower(host)),
        cookie.fill_path(path, req_path), secure, http_only, same_site,
        host_only}

# a dot continues the scan, a digit keeps it, anything else stops
def cookie.ipv4.step(dot: Bool, digit: Bool, if_dot: Unit -> Bool,
  if_digit: Unit -> Bool) -> Bool:
  match dot digit:
    case True{} _:
      if_dot(Unit{})
    case False{} True{}:
      if_digit(Unit{})
    case False{} False{}:
      False{}

# true when the host is only digits and dots and contains a dot
def cookie.ipv4.go(host: String, seen: Bool) -> Bool:
  match host:
    case SNil{}:
      seen
    case SCon{h, +t}:
      +u = Char.to_u32(h)
      cookie.ipv4.step(U32.is_eq(u, 46),
        Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)),
        _u => cookie.ipv4.go(t, True{}), _d => cookie.ipv4.go(t, seen))

# IPv4 literal (no subdomain match, RFC 6265 §5.1.3)
def cookie.ipv4(host: String) -> Bool:
  cookie.ipv4.go(host, False{})

# suffix match when the host is not an IPv4 address
def cookie.domain_suffix(host: String, domain: String, ip: Bool) -> Bool:
  match ip:
    case True{}:
      False{}
    case False{}:
      String.ends_with(host, "." ++ domain)

# exact match, else the suffix rule
def cookie.domain_eq(+host: String, +domain: String, same: Bool) -> Bool:
  match same:
    case True{}:
      True{}
    case False{}:
      cookie.domain_suffix(host, domain, cookie.ipv4(host))

# domain-match (RFC 6265 §5.1.3). Host and domain are compared lowercase.
def cookie.domain_match(+host: String, +domain: String) -> Bool:
  cookie.domain_eq(host, domain, String.eq(host, domain))

# host-only is exact; a Domain attribute uses domain-match
def cookie.domain_ok(host: String, domain: String, host_only: Bool) -> Bool:
  match host_only:
    case True{}:
      String.eq(String.to_lower(host), String.to_lower(domain))
    case False{}:
      cookie.domain_match(String.to_lower(host), String.to_lower(domain))

# the next request character is `/`, or the cookie-path already ended in `/`
def cookie.path_slash(+req: String, +cpath: String, slash: Bool) -> Bool:
  match slash:
    case True{}:
      True{}
    case False{}:
      String.starts_with(String.drop(req, String.length(cpath)), "/")

# identical paths match; otherwise the prefix rules (RFC 6265 §5.1.4)
def cookie.path_rest(+req: String, +cpath: String, same: Bool) -> Bool:
  match same:
    case True{}:
      True{}
    case False{}:
      cookie.path_slash(req, cpath, String.ends_with(cpath, "/"))

# path-match once the cookie-path is known to be a prefix
def cookie.path_prefix(+req: String, +cpath: String, hit: Bool) -> Bool:
  match hit:
    case False{}:
      False{}
    case True{}:
      cookie.path_rest(req, cpath, String.eq(req, cpath))

# path-match (RFC 6265 §5.1.4)
def cookie.path_ok(+req: String, +cpath: String) -> Bool:
  cookie.path_prefix(req, cpath, String.starts_with(req, cpath))

# Secure cookies ride only on TLS (RFC 6265 §5.4)
def cookie.send.secure(tls: Bool, secure: Bool) -> Bool:
  match secure:
    case False{}:
      True{}
    case True{}:
      tls

# path-match, then the Secure bit
def cookie.send.path(tls: Bool, secure: Bool, ok: Bool) -> Bool:
  match ok:
    case False{}:
      False{}
    case True{}:
      cookie.send.secure(tls, secure)

# domain-match, then path-match
def cookie.send.domain(req: String, tls: Bool, secure: Bool, cpath: String,
  ok: Bool) -> Bool:
  match ok:
    case False{}:
      False{}
    case True{}:
      cookie.send.path(tls, secure, cookie.path_ok(req, cpath))

# whether this cookie is sent on this request (RFC 6265 §5.4)
def cookie.send(host: String, req_path: String, tls: Bool, c: Cookie) -> Bool:
  match c:
    case Cookie{name, value, expires, max_age, domain, path, secure, http_only,
      same_site, host_only}:
      cookie.send.domain(req_path, tls, secure, path,
        cookie.domain_ok(host, domain, host_only))

# no Max-Age means a session cookie (still sendable). 0 means already expired.
def cookie.alive.of(age: Nat, m: Maybe<&2, Nat>) -> Bool:
  match m:
    case None{}:
      True{}
    case Some{n}:
      Nat.is_lt(age, n)

# Max-Age against an age in seconds. Expires is not compared to a clock.
def cookie.alive(max_age: String, age: Nat) -> Bool:
  cookie.alive.of(age, Http.digits.read(max_age))

# cons when the cookie matches the request
def cookie.select.cons(ok: Bool, c: Cookie, rest: Unit -> List<&2, Cookie>)
  -> List<&2, Cookie>:
  match ok:
    case False{}:
      rest(Unit{})
    case True{}:
      c <> rest(Unit{})

# cookies that would be sent (domain, path, secure)
def cookie.select(cs: List<&2, Cookie>, +host: String, +req_path: String,
  +tls: Bool) -> List<&2, Cookie>:
  match cs:
    case []:
      []
    case +h <> t:
      cookie.select.cons(cookie.send(host, req_path, tls, h), h,
        _u => cookie.select(t, host, req_path, tls))
