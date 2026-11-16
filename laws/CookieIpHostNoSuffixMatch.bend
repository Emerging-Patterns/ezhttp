# For every request host that is an IPv4 literal, a Domain cookie whose
# domain differs from it (compared lowercase) does not match: an IP address
# has no subdomains (RFC 6265 §5.1.3).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): an IPv4 host matches no domain but itself
law cookie_domain_ip:
  for +host: String
  for +domain: String
  for e1: {False{} == String.eq(String.to_lower(host), String.to_lower(domain))
    : Bool}
  for e2: {True{} == Cookie.cookie.ipv4(String.to_lower(host)) : Bool}
  {Cookie.cookie.domain_ok(host, domain, False{}) == False{} : Bool}
