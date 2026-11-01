import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): without max-age the response is not treated as fresh
law fresh_public_only:
  {Cache.cache.fresh(Cache.cache.parse("public"), 0n) == False{} : Bool}
