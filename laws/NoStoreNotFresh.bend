import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.3): no-store is not fresh
law fresh_no_store:
  {Cache.cache.fresh(Cache.cache.parse("no-store, max-age=10"), 0n)
    == False{} : Bool}
