import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.2): Max-Age replaces the cookie's max-age and nothing
# else
law cookie_age_sets:
  for name: String
  for value: String
  for expires: String
  for max_age: String
  for domain: String
  for path: String
  for secure: Bool
  for http_only: Bool
  for same_site: String
  for host_only: Bool
  for age: String
  {Cookie.cookie.age(Cookie.Cookie{name, value, expires, max_age, domain, path,
    secure, http_only, same_site, host_only}, age)
    == Cookie.Cookie{name, value, expires, age, domain, path, secure,
      http_only, same_site, host_only} : Cookie.Cookie}
