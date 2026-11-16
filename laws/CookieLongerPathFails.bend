# For every request path and cookie-path, a cookie-path that the request
# path does not start with (a longer one, such as `/app/` for `/app`) does
# not path-match (RFC 6265 §5.1.4).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): no prefix, no path-match
law cookie_path_not_prefix:
  for +req: String
  for +cpath: String
  for e: {False{} == String.starts_with(req, cpath) : Bool}
  {Cookie.cookie.path_ok(req, cpath) == False{} : Bool}
