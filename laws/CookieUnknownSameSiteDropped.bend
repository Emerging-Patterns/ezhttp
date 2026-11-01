import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): an unknown SameSite attribute is dropped
law cookie_samesite_unknown:
  {Cookie.cookie.parse("a=b; SameSite=weird")
    == Some{Cookie.cookie.new("a", "b")} : Maybe<&2, Cookie.Cookie>}
