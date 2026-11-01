import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.1.1): a non-digit max-age is not recorded
law cache_max_age_ignores_junk:
  {Cache.cache.parse("max-age=nope")
    == Cache.Cc{False{}, False{}, False{}, False{}, "", ""} : Cache.Cc}
