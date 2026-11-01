import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): Max-Age 1 is alive at age 0 and stale at age 1
law cookie_max_age_one:
  {Bool.and(Cookie.cookie.alive("1", 0n),
      Bool.not(Cookie.cookie.alive("1", 1n))) == True{} : Bool}
