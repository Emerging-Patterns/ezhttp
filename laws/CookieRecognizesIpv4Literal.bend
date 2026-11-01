import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): an IPv4 literal is recognized, a name is not
law cookie_ipv4_literal:
  {Cookie.cookie.ipv4("192.0.2.1") == True{} : Bool}
