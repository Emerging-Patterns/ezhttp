import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a host-only cookie is not sent to another host
law cookie_send_other_host:
  {Cookie.cookie.send("other.com", "/", False{},
      Cookie.cookie.receive("example.com", "/", Cookie.cookie.new("a", "b")))
    == False{} : Bool}
