import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): Max-Age 0 is not alive at age 0
law cookie_max_age_zero:
  {Cookie.cookie.alive("0", 0n) == False{} : Bool}
