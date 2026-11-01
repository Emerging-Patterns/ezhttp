import Base
import ../src/cookie.bend as Cookie

# LAW (RFC 6265 §5.4): a host-only cookie stores the response host and default-path
law cookie_receive_host_only:
  {Cookie.cookie.line(Cookie.cookie.receive("Example.COM", "/a/b",
      Cookie.cookie.new("a", "b")))
    == "a=b; Path=/a" : String}
