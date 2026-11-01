import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.1): userinfo is stripped; it is not the host
law url_userinfo_stripped:
  {Url.parse("http://user:pass@example.com/a")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}
