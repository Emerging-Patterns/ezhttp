import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.3): an explicit port wins over the scheme default
law url_ipv4_port:
  {Url.parse("http://192.0.2.1:8080/a")
    == Url.Loc{"http", "192.0.2.1", 8080, "/a"} : Url.Loc}
