# For every list of cookies, the Cookie request field value is the
# `name=value` pair of each cookie with a name, in order, joined by `; `,
# a cookie with an empty name left out (RFC 6265 §5.4 step 4).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4 step 4): the pairs joined by `; `
law cookie_join:
  for cs: List<&2, Cookie.Cookie>
  {Cookie.cookie.join(cs) == String.join(Cookie.cookie.pairs(cs), "; ")
    : String}

# LAW: no cookies, no pairs
law cookie_pairs_nil:
  for cs: List<&2, Cookie.Cookie>
  for e: {[] == cs : List<&2, Cookie.Cookie>}
  {Cookie.cookie.pairs(cs) == [] : List<&2, String>}

# LAW: a cookie with a name gives its pair, then the rest
law cookie_pairs_kept:
  for +name: String
  for +value: String
  for +expires: String
  for +max_age: String
  for +domain: String
  for +path: String
  for +secure: Bool
  for +http_only: Bool
  for +same_site: String
  for +host_only: Bool
  for t: List<&2, Cookie.Cookie>
  for e: {False{} == String.is_empty(name) : Bool}
  {Cookie.cookie.pairs(Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only} <> t)
    == (name ++ "=" ++ value) <> Cookie.cookie.pairs(t) : List<&2, String>}

# LAW: a cookie with an empty name gives nothing
law cookie_pairs_dropped:
  for +name: String
  for +value: String
  for +expires: String
  for +max_age: String
  for +domain: String
  for +path: String
  for +secure: Bool
  for +http_only: Bool
  for +same_site: String
  for +host_only: Bool
  for t: List<&2, Cookie.Cookie>
  for e: {True{} == String.is_empty(name) : Bool}
  {Cookie.cookie.pairs(Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only} <> t)
    == Cookie.cookie.pairs(t) : List<&2, String>}
