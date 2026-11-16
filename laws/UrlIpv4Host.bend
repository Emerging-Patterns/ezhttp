import Base
import ../src/url.bend as Url

# For every authority split on its colons, the host is the piece before the
# first colon, unchanged: a name or an IPv4 literal alike.

# LAW (RFC 3986 §3.2.2): the host is everything before the port's colon
law host_before_colon:
  for host: String
  for rest: List<&2, String>
  {Url.host.of(host <> rest) == host : String}
