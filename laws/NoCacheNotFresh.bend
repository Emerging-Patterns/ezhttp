import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.2): no-cache is not fresh
law fresh_no_cache:
  {Cache.cache.fresh(Cache.cache.parse("no-cache, max-age=10"), 0n)
    == False{} : Bool}
