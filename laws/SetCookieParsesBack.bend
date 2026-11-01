import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §4.1.1): Set-Cookie parses back to those attributes
law cookie_parse_round_trip:
  {Cookie.cookie.parse("a=b; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Max-Age=12; Domain=example.com; Path=/app; Secure; HttpOnly; SameSite=Lax")
    == Some{Cookie.Cookie{"a", "b", "Wed, 21 Oct 2015 07:28:00 GMT", "12",
      "example.com", "/app", True{}, True{}, "Lax", False{}}}
    : Maybe<&2, Cookie.Cookie>}
