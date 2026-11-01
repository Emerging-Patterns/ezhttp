import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): max-age=1 is fresh at 0 and stale at 1
law fresh_max_age_one:
  {Bool.and(Cache.cache.fresh(Cache.cache.parse("max-age=1"), 0n),
      Bool.not(Cache.cache.fresh(Cache.cache.parse("max-age=1"), 1n)))
    == True{} : Bool}
