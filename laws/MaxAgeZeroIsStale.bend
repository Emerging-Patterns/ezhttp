import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): max-age=0 is stale at age 0
law fresh_max_age_zero:
  {Cache.cache.fresh(Cache.cache.parse("max-age=0"), 0n) == False{} : Bool}
