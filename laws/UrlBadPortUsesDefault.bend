import Base
import ../src/url.bend as Url

# For every host, port text that does not read as a number, later pieces and
# scheme, an authority split on its colons gets the port its scheme implies.

# LAW (RFC 3986 §3.2.3): a non-numeric port falls back to the scheme default
law port_junk:
  for host: String
  for port: String
  for rest: List<&2, String>
  for +scheme: String
  for e: {None{} == U32.read(port) : Maybe<&2, U32>}
  {Url.port.of(host <> port <> rest, scheme) == Url.dflt(scheme) : U32}
