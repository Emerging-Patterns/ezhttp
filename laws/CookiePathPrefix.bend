import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a path-match allows a prefix whose next character is `/`
law cookie_path_prefix:
  {Cookie.cookie.path_ok("/app/x", "/app") == True{} : Bool}
