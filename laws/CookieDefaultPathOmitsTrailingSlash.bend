import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a trailing slash keeps the directory, not the slash
law cookie_default_path_trailing:
  {Cookie.cookie.default_path("/foo/bar/") == "/foo/bar" : String}
