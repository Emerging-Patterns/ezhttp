# For every request host and cookie domain that differ (compared
# lowercase), when the host is not an IPv4 literal a Domain cookie
# domain-matches exactly when the host ends with `.` and the domain, so
# `www.example.com` matches `example.com` and `notexample.com` does not
# (RFC 6265 §5.1.3).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.1.3): a host name matches a domain it ends with after a dot
law cookie_domain_suffix:
  for +host: String
  for +domain: String
  for e1: {False{} == String.eq(String.to_lower(host), String.to_lower(domain))
    : Bool}
  for e2: {False{} == Cookie.cookie.ipv4(String.to_lower(host)) : Bool}
  {Cookie.cookie.domain_ok(host, domain, False{})
    == String.ends_with(String.to_lower(host), "." ++ String.to_lower(domain))
    : Bool}
