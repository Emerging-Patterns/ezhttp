import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): a domain-match allows a leading-dot suffix
law cookie_domain_suffix:
  {Cookie.cookie.domain_ok("www.example.com", "example.com", False{})
    == True{} : Bool}
