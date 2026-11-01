import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.3): a trailing slash is part of the path
law url_trailing_slash:
  {Url.parse("http://example.com/a/")
    == Url.Loc{"http", "example.com", 80, "/a/"} : Url.Loc}
