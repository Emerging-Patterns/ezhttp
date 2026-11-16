# For every cookie and Domain attribute value, the attribute (named
# `domain` once lowercased) stores the value lowercased as the cookie's
# domain and clears host-only (RFC 6265 §5.2.3), leaving every other field
# as it was.
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.3): Domain is stored lowercase
law cookie_named_domain:
  for c: Cookie.Cookie
  for value: String
  {Cookie.cookie.named(c, "domain", value)
    == Cookie.cookie.domain(c, String.to_lower(value)) : Cookie.Cookie}

# LAW (§5.3 step 6): a Domain attribute clears host-only
law cookie_domain_sets:
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
  for host: String
  {Cookie.cookie.domain(Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only}, host)
    == Cookie.Cookie{name, value, expires, max_age, host, path, secure,
      http_only, same_site, False{}} : Cookie.Cookie}
