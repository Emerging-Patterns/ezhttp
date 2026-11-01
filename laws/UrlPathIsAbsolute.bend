import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.3 path-absolute / path-abempty with authority): the path a
# URL comes apart into is always absolute. The request-target is an
# absolute-path (RFC 9112 §3.2.1).
law path_absolute:
  for ps: List<&2, String>
  {String.starts_with(Url.path.of(ps), "/") == True{} : Bool}
