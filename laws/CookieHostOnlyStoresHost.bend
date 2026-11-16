# For every response host, request path and cookie received: a host-only
# cookie stores the response host lowercased as its domain, a Domain cookie
# keeps its domain; a cookie with no Path takes the request path's
# default-path, any other keeps its Path (RFC 6265 §5.3 steps 6-7); every
# other field is kept.
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.3): receiving fills the domain and the path
law cookie_receive:
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
  for +host: String
  for +req: String
  {Cookie.cookie.receive(host, req, Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only})
    == Cookie.Cookie{name, value, expires, max_age,
      Cookie.cookie.fill_domain(domain, host_only, String.to_lower(host)),
      Cookie.cookie.fill_path(path, req), secure, http_only, same_site,
      host_only} : Cookie.Cookie}

# LAW (§5.3 step 6): a host-only cookie takes the host
law cookie_fill_domain_host_only:
  for domain: String
  for +host: String
  {Cookie.cookie.fill_domain(domain, True{}, host) == host : String}

# LAW (§5.3 step 6): a Domain cookie keeps its domain
law cookie_fill_domain_set:
  for +domain: String
  for host: String
  {Cookie.cookie.fill_domain(domain, False{}, host) == domain : String}

# LAW (§5.3 step 7): no Path, the default-path
law cookie_fill_path_empty:
  for +path: String
  for +req: String
  for e: {True{} == String.is_empty(path) : Bool}
  {Cookie.cookie.fill_path(path, req) == Cookie.cookie.default_path(req)
    : String}

# LAW (§5.3 step 7): a Path is kept
law cookie_fill_path_set:
  for +path: String
  for +req: String
  for e: {False{} == String.is_empty(path) : Bool}
  {Cookie.cookie.fill_path(path, req) == path : String}
