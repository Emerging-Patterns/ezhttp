import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a host-only cookie is sent on its host and default-path
law cookie_send_host_only:
  {Cookie.cookie.send("example.com", "/a/x", False{},
      Cookie.cookie.receive("Example.COM", "/a/b", Cookie.cookie.new("a", "b")))
    == True{} : Bool}
