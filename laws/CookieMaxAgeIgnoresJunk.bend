# For every cookie and Max-Age attribute value (named `max-age` once
# lowercased), a value that reads as decimal digits replaces the cookie's
# Max-Age with the value as written, and any other value is ignored and the
# cookie kept as it was (RFC 6265 §5.2.2).
import Base
import ../src/http.bend as Http
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.2): Max-Age is read as digits
law cookie_named_max_age:
  for c: Cookie.Cookie
  for +value: String
  {Cookie.cookie.named(c, "max-age", value)
    == Cookie.cookie.age_ok(c, value, Http.digits.read(value)) : Cookie.Cookie}

# LAW (§5.2.2): a Max-Age that is not digits is ignored
law cookie_age_junk:
  for +c: Cookie.Cookie
  for raw: String
  {Cookie.cookie.age_ok(c, raw, None{}) == c : Cookie.Cookie}

# LAW (§5.2.2): a Max-Age of digits is stored as written
law cookie_age_digits:
  for c: Cookie.Cookie
  for raw: String
  for n: Nat
  {Cookie.cookie.age_ok(c, raw, Some{n}) == Cookie.cookie.age(c, raw)
    : Cookie.Cookie}
