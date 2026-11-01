import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a cookie with no Domain does not match a different host
law cookie_send_unset_domain:
  {Cookie.cookie.send("h", "/", False{}, Cookie.cookie.new("a", "b"))
    == False{} : Bool}
