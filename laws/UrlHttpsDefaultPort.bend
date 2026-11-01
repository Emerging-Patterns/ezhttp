import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.3 / RFC 2818): https with no port is 443
law url_https_default_port:
  {Url.parse("https://example.com/a")
    == Url.Loc{"https", "example.com", 443, "/a"} : Url.Loc}
