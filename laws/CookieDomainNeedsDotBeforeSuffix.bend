import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): a suffix without the separating dot does not match
law cookie_domain_not_suffix:
  {Cookie.cookie.domain_ok("notexample.com", "example.com", False{})
    == False{} : Bool}
