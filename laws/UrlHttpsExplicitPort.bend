import Base
import ../src/url.bend as Url

# For every host, port text that reads as a number `n`, later pieces and
# scheme, an authority split on its colons names port `n`, whatever the
# scheme would imply.

# LAW (RFC 3986 §3.2.3): an explicit numeric port wins over the default
law port_explicit:
  for host: String
  for port: String
  for rest: List<&2, String>
  for n: U32
  for scheme: String
  for e: {Some{n} == U32.read(port) : Maybe<&2, U32>}
  {Url.port.of(host <> port <> rest, scheme) == n : U32}
