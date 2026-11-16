import Base
import ../src/url.bend as Url

# LAW (RFC 9110 §4.2.2): every scheme spelled `https` implies port 443
# (laws/OtherSchemesDefaultTo80.bend has every other scheme)
law dflt_https:
  for +scheme: String
  for e: {True{} == String.eq(scheme, "https") : Bool}
  {Url.dflt(scheme) == 443 : U32}
