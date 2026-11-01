import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.4): identical paths match
law cookie_path_identical:
  {Cookie.cookie.path_ok("/app", "/app") == True{} : Bool}
