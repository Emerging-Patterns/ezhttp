import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a session cookie (no Max-Age) stays sendable
law cookie_session_alive:
  {Cookie.cookie.alive("", 5n) == True{} : Bool}
