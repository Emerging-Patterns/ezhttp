# For every request host and cookie domain, a host-only cookie matches
# exactly the host it was set by, and a Domain cookie matches a host
# identical to its domain, an IPv4 literal included (RFC 6265 §5.1.3 rule 1,
# §5.4 step 1), both compared lowercase.
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): identical host and domain match
law cookie_domain_exact:
  for +host: String
  for +domain: String
  for e: {True{} == String.eq(String.to_lower(host), String.to_lower(domain))
    : Bool}
  {Cookie.cookie.domain_ok(host, domain, False{}) == True{} : Bool}

# LAW (§5.4 step 1): a host-only cookie matches only its own host
law cookie_domain_host_only:
  for host: String
  for domain: String
  {Cookie.cookie.domain_ok(host, domain, True{})
    == String.eq(String.to_lower(host), String.to_lower(domain)) : Bool}
