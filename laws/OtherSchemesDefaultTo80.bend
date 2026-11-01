import Base
import ../src/url.bend as Url

# LAW (RFC 3986 §3.2.3): only https implies 443; other schemes get 80
law dflt_plain:
  for +scheme: String
  for e: {False{} == String.eq(scheme, "https") : Bool}
  {Url.dflt(scheme) == 80 : U32}
