import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): an empty cookie-name is rejected
law cookie_rejects_empty_name:
  {Cookie.cookie.parse("=nope") == None{} : Maybe<&2, Cookie.Cookie>}
