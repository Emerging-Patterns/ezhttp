import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.1): the last `@` piece is the hostport
law url_userinfo_last_at:
  {Url.parse("http://a@b@example.com/z")
    == Url.Loc{"http", "example.com", 80, "/z"} : Url.Loc}
