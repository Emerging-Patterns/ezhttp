import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): a registered name is not an IPv4 address
law cookie_ipv4_name:
  {Cookie.cookie.ipv4("example.com") == False{} : Bool}
