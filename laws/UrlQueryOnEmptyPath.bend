import Base
import ../src/url.bend as Url

# For every path and non-empty query, the origin-form target is the path,
# `?` and the query; an empty path (`/`) with a query is `/?query`.

# LAW (RFC 3986 §3.4, RFC 9112 §3.2.1): a query follows the path after `?`
law path_target_query:
  for path: String
  for +query: String
  for e: {False{} == String.is_empty(query) : Bool}
  {Url.path.target(path, query) == path ++ "?" ++ query : String}
