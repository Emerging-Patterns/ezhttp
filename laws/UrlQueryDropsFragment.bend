import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.4, §3.5): the query stays on the path; the fragment does not
law url_query_drops_fragment:
  {Url.parse("http://example.com/a/b?x=1#frag")
    == Url.Loc{"http", "example.com", 80, "/a/b?x=1"} : Url.Loc}
