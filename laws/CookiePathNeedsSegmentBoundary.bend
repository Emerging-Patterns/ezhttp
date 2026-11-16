# For every request path and cookie-path, a cookie-path that is a prefix of
# a different request path, does not end with `/`, and is followed in it by
# a character other than `/` does not path-match, so `/app` does not match
# `/application` (RFC 6265 §5.1.4).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a prefix that ends inside a segment does not match
law cookie_path_not_boundary:
  for +req: String
  for +cpath: String
  for e1: {True{} == String.starts_with(req, cpath) : Bool}
  for e2: {False{} == String.eq(req, cpath) : Bool}
  for e3: {False{} == String.ends_with(cpath, "/") : Bool}
  for e4: {False{} == String.starts_with(String.drop(req, String.length(cpath)),
    "/") : Bool}
  {Cookie.cookie.path_ok(req, cpath) == False{} : Bool}
