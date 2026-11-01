import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): max-age overrides Expires for freshness
law fresh_max_age_overrides_expires:
  {Cache.cache.fresh(Cache.cache.note("max-age=0",
      "Wed, 21 Oct 2099 07:28:00 GMT"), 0n) == False{} : Bool}
