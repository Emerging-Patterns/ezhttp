import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): a present max-age is what freshness uses
law cache_max_age_present:
  {Cache.cache.max_age(Cache.cache.parse("max-age=1")) == True{} : Bool}
