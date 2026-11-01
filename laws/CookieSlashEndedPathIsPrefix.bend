import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a cookie-path that already ends in `/` is a prefix
law cookie_path_slash_prefix:
  {Cookie.cookie.path_ok("/app/x", "/app/") == True{} : Bool}
