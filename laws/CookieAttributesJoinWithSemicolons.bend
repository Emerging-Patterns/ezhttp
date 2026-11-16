# For every cookie, its Set-Cookie field value (RFC 6265 §4.1.1) is
# `name=value`, then `; Expires=`, `; Max-Age=`, `; Domain=` (only when a
# Domain attribute was set, not host-only), `; Path=` each with its value
# when the value is not empty, then `; Secure` and `; HttpOnly` when their
# flags are set, then `; SameSite=` with its value when not empty: the
# attributes joined by `; `.
import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): the attributes in order after name=value
law cookie_line:
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
  {Cookie.cookie.line(Cookie.Cookie{name, value, expires, max_age, domain, path, secure,
    http_only, same_site, host_only})
    == name ++ "=" ++ value
      ++ Cookie.cookie.opt("; Expires=", expires)
      ++ Cookie.cookie.opt("; Max-Age=", max_age)
      ++ Cookie.cookie.domain_text(domain, host_only)
      ++ Cookie.cookie.opt("; Path=", path)
      ++ Cookie.cookie.mark("Secure", secure)
      ++ Cookie.cookie.mark("HttpOnly", http_only)
      ++ Cookie.cookie.opt("; SameSite=", same_site) : String}

# LAW: an empty attribute value writes nothing
law cookie_opt_empty:
  for prefix: String
  for +value: String
  for e: {True{} == String.is_empty(value) : Bool}
  {Cookie.cookie.opt(prefix, value) == "" : String}

# LAW: any other value writes its prefix and the value
law cookie_opt_set:
  for +prefix: String
  for +value: String
  for e: {False{} == String.is_empty(value) : Bool}
  {Cookie.cookie.opt(prefix, value) == prefix ++ value : String}

# LAW: a set flag writes `; ` and its label
law cookie_mark_on:
  for +label: String
  {Cookie.cookie.mark(label, True{}) == "; " ++ label : String}

# LAW: an unset flag writes nothing
law cookie_mark_off:
  for label: String
  {Cookie.cookie.mark(label, False{}) == "" : String}

# LAW: a host-only cookie writes no Domain
law cookie_domain_text_host_only:
  for domain: String
  {Cookie.cookie.domain_text(domain, True{}) == "" : String}

# LAW: a Domain attribute is written as `; Domain=`
law cookie_domain_text_set:
  for +domain: String
  {Cookie.cookie.domain_text(domain, False{})
    == Cookie.cookie.opt("; Domain=", domain) : String}
