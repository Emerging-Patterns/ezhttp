import Base
import ../src/url.bend as Url

# --- thicker fence: more closed witnesses of the same RFCs ---

# LAW (RFC 3986 §3.2.3): http with no port is 80
law url_http_default_port:
  {Url.parse("http://example.com/a")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}
