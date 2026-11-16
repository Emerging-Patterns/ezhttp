# proofs of laws/CookieIpHostNoSuffixMatch.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieIpHostNoSuffixMatch.bend as Laws

def Laws.cookie_domain_ip(host, domain, e1, e2):
  %e1 : {Cookie.cookie.domain_eq(String.to_lower(host), String.to_lower(domain), _)
    == False{} : Bool}
  %e2 : {Cookie.cookie.domain_suffix(String.to_lower(host), String.to_lower(domain), _)
    == False{} : Bool}
  {==}
