import Base
import ../src/url.bend as Url

# For every hier-part split on `?`, the part before the first `?` is the
# hier-part and the query is the rest joined back with `?`, so a later `?`
# stays in the query.

# LAW (RFC 3986 §3.4): the hier-part ends at the first `?`
law query_hier_first:
  for hier: String
  for rest: List<&2, String>
  {Url.query.hier(hier <> rest) == hier : String}

# LAW (RFC 3986 §3.4): the query keeps every later `?`
law query_keeps_question:
  for hier: String
  for rest: List<&2, String>
  {Url.query.text(hier <> rest) == String.join(rest, "?") : String}
