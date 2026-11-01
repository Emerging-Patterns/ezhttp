import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): an age equal to max-age is stale
law fresh_max_age_limit:
  {Cache.cache.fresh(Cache.cache.parse("max-age=10"), 10n) == False{} : Bool}
