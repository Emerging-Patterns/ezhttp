# For every request and cookie whose domain matches the request host, the
# cookie is sent exactly when its path matches the request path and, when
# it is Secure, the request is over TLS (RFC 6265 §5.4 step 1).
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4 step 1): a domain-match leaves path and Secure to decide
law cookie_send_domain_hit:
  for +host: String
  for +req: String
  for +tls: Bool
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
  for e: {True{} == Cookie.cookie.domain_ok(host, domain, host_only) : Bool}
  {Cookie.cookie.send(host, req, tls, Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only})
    == Cookie.cookie.send.path(tls, secure, Cookie.cookie.path_ok(req, path))
    : Bool}

# LAW: no path-match, not sent
law cookie_send_path_miss:
  for tls: Bool
  for secure: Bool
  {Cookie.cookie.send.path(tls, secure, False{}) == False{} : Bool}

# LAW: a path-match leaves the Secure rule to decide
law cookie_send_path_hit:
  for +tls: Bool
  for +secure: Bool
  {Cookie.cookie.send.path(tls, secure, True{})
    == Cookie.cookie.send.secure(tls, secure) : Bool}
