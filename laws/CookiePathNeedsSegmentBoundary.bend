import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a longer segment is not a path-match
law cookie_path_not_prefix:
  {Cookie.cookie.path_ok("/application", "/app") == False{} : Bool}
