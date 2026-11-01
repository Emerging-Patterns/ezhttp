import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.4): a later `?` stays inside the query
law url_query_keeps_question:
  {Url.parse("http://example.com/a?x=1?y=2")
    == Url.Loc{"http", "example.com", 80, "/a?x=1?y=2"} : Url.Loc}
