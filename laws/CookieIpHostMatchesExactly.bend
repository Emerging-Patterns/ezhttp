import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): an IPv4 host matches its own address exactly
law cookie_domain_ip_exact:
  {Cookie.cookie.domain_ok("192.0.2.1", "192.0.2.1", False{}) == True{} : Bool}
