import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): an IPv4 host does not domain-match a suffix
law cookie_domain_ip_suffix:
  {Cookie.cookie.domain_ok("192.0.2.1", "2.1", False{}) == False{} : Bool}
