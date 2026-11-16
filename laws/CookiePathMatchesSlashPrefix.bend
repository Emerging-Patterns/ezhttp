# For every request path and cookie-path, a cookie-path that is a prefix of
# the request path, when the first request character after it is `/`,
# path-matches it, so `/app` matches `/app/x` (RFC 6265 §5.1.4, third
# rule).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a prefix followed by / matches
law cookie_path_prefix:
  for +req: String
  for +cpath: String
  for e1: {True{} == String.starts_with(req, cpath) : Bool}
  for e2: {True{} == String.starts_with(String.drop(req, String.length(cpath)),
    "/") : Bool}
  {Cookie.cookie.path_ok(req, cpath) == True{} : Bool}
