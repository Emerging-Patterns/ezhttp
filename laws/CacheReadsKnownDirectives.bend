import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2): no-store, no-cache, public, private, and max-age
law cache_directives:
  {Cache.cache.parse("no-store, no-cache, public, private, max-age=5")
    == Cache.Cc{True{}, True{}, True{}, True{}, "5", ""} : Cache.Cc}
