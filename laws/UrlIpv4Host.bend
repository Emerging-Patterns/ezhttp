import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.2): an IPv4 literal is the host
law url_ipv4_host:
  {Url.parse("http://192.0.2.1/a")
    == Url.Loc{"http", "192.0.2.1", 80, "/a"} : Url.Loc}
