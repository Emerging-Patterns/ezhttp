import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.5): a `?` inside the fragment is not a query
law url_fragment_hides_query:
  {Url.parse("http://example.com/a#b?c")
    == Url.Loc{"http", "example.com", 80, "/a"} : Url.Loc}
