import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.3, §3.4): an empty path with a query is `/?query`
law url_query_on_empty_path:
  {Url.parse("http://example.com?x=1")
    == Url.Loc{"http", "example.com", 80, "/?x=1"} : Url.Loc}
