import Base
import ../src/url.bend as Url

# For every authority with nothing after it (no `/`), the path is `/`.

# LAW (RFC 3986 §3.3, RFC 9112 §3.2.1): an empty path is sent as `/`
law path_empty:
  for authority: String
  {Url.path.of([authority]) == "/" : String}
