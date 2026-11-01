import Base
import ../src/url.bend as Url

# LAW: https implies 443
law dflt_https:
  {Url.dflt("https") == 443 : U32}
