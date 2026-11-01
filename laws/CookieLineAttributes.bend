import Base
import ../src/cookie.bend as Cookie

# --- RFC 6265 cookies ---

# LAW (RFC 6265 §4.1.1): attributes serialize with `; ` separators
law cookie_line_attributes:
  {Cookie.cookie.line(Cookie.Cookie{"a", "b",
      "Wed, 21 Oct 2015 07:28:00 GMT", "12", "example.com", "/app",
      True{}, True{}, "Lax", False{}})
    == "a=b; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Max-Age=12; Domain=example.com; Path=/app; Secure; HttpOnly; SameSite=Lax"
    : String}
