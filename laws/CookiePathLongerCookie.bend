import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): a cookie-path the request does not extend fails
law cookie_path_longer_cookie:
  {Cookie.cookie.path_ok("/app", "/app/") == False{} : Bool}
