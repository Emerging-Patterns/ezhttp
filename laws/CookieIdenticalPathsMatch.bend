# For every path, a cookie-path path-matches the identical request path
# (RFC 6265 §5.1.4, first rule).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): identical paths match
law cookie_path_identical:
  for +p: String
  {Cookie.cookie.path_ok(p, p) == True{} : Bool}
