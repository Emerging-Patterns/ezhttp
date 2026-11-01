import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): an age under Max-Age is still alive
law cookie_max_age_open:
  {Cookie.cookie.alive("10", 0n) == True{} : Bool}
