# proofs of laws/CookieIpHostMatchesExactly.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieIpHostMatchesExactly.bend as Laws

def Laws.cookie_domain_exact(host, domain, e):
  %e : {Cookie.cookie.domain_eq(String.to_lower(host), String.to_lower(domain), _)
    == True{} : Bool}
  {==}

def Laws.cookie_domain_host_only(_host, _domain):
  {==}
