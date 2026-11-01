import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): default-path `/` matches a longer request path
law cookie_path_root:
  {Cookie.cookie.path_ok("/a", "/") == True{} : Bool}
