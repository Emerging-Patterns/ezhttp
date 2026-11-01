import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2): an unrecognized directive is ignored
law cache_ignores_s_maxage:
  {Cache.cache.parse("s-maxage=9, max-age=3")
    == Cache.Cc{False{}, False{}, False{}, False{}, "3", ""} : Cache.Cc}
