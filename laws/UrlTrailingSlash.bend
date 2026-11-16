import Base
import ../src/url.bend as Url

# For every hier-part split on `/`, the path is `/` and the pieces after the
# authority joined back with `/`, each kept as written, so an empty last
# piece (a trailing slash) stays.

# LAW (RFC 3986 §3.3): the path keeps its segments, trailing slash included
law path_rejoined:
  for authority: String
  for segments: List<&2, String>
  {Url.path.of(authority <> segments) == "/" ++ String.join(segments, "/")
    : String}
