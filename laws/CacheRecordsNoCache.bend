import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.2): no-cache alone is recorded and not fresh
law cache_no_cache_alone:
  {Cache.cache.parse("no-cache")
    == Cache.Cc{False{}, True{}, False{}, False{}, "", ""} : Cache.Cc}
