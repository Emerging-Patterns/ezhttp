# For every request path and cookie-path, a cookie-path that is a prefix of
# the request path and ends with `/` path-matches it, so `/` matches every
# path and `/app/` matches `/app/x` (RFC 6265 §5.1.4, second rule).
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a prefix ending in / matches
law cookie_path_slash_prefix:
  for +req: String
  for +cpath: String
  for e1: {True{} == String.starts_with(req, cpath) : Bool}
  for e2: {True{} == String.ends_with(cpath, "/") : Bool}
  {Cookie.cookie.path_ok(req, cpath) == True{} : Bool}
