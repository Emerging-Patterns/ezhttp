import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.2.2): a Max-Age that is not digits is ignored
law cookie_max_age_ignores_junk:
  {Cookie.cookie.parse("a=b; Max-Age=nope")
    == Some{Cookie.cookie.new("a", "b")} : Maybe<&2, Cookie.Cookie>}
