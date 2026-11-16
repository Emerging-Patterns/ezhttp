# For every request and cookie, a cookie whose domain does not match the
# request host (host-only: not that exact host; no Domain and no host:
# never) is not sent (RFC 6265 §5.4 step 1).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4 step 1): no domain-match, not sent
law cookie_send_domain_miss:
  for +host: String
  for req: String
  for tls: Bool
  for +name: String
  for +value: String
  for +expires: String
  for +max_age: String
  for +domain: String
  for +path: String
  for +secure: Bool
  for +http_only: Bool
  for +same_site: String
  for +host_only: Bool
  for e: {False{} == Cookie.cookie.domain_ok(host, domain, host_only) : Bool}
  {Cookie.cookie.send(host, req, tls, Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only}) == False{} : Bool}
