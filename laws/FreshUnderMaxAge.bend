import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): an age under max-age is fresh
law fresh_max_age_open:
  {Cache.cache.fresh(Cache.cache.parse("max-age=10"), 0n) == True{} : Bool}
