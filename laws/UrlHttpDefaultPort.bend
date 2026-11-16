import Base
import ../src/url.bend as Url

# For every host and scheme, an authority that names no port (no colon) gets
# the port its scheme implies: 80, or 443 for https
# (laws/OtherSchemesDefaultTo80.bend, laws/HttpsDefaultsTo443.bend).

# LAW (RFC 3986 §3.2.3): an authority without a port takes the scheme's
law port_absent:
  for host: String
  for scheme: String
  {Url.port.of([host], scheme) == Url.dflt(scheme) : U32}
