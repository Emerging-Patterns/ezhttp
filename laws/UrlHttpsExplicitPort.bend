import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.3): an explicit https port is kept
law url_https_explicit_port:
  {Url.parse("https://example.com:8443/a")
    == Url.Loc{"https", "example.com", 8443, "/a"} : Url.Loc}
