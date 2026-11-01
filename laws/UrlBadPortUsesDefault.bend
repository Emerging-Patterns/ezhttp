import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.3): a non-numeric port falls back to the scheme default
law url_bad_port_uses_default:
  {Url.parse("http://example.com:abc/x")
    == Url.Loc{"http", "example.com", 80, "/x"} : Url.Loc}
