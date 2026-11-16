# proofs of laws/CookieDomainMatchesDotSuffix.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieDomainMatchesDotSuffix.bend as Laws

def Laws.cookie_domain_suffix(host, domain, e1, e2):
  %e1 : {Cookie.cookie.domain_eq(String.to_lower(host), String.to_lower(domain), _)
    == String.ends_with(String.to_lower(host), "." ++ String.to_lower(domain))
    : Bool}
  %e2 : {Cookie.cookie.domain_suffix(String.to_lower(host), String.to_lower(domain), _)
    == String.ends_with(String.to_lower(host), "." ++ String.to_lower(domain))
    : Bool}
  {==}
