import Base
import ../src/cache.bend as Cache

# --- RFC 9111 cache directives ---

# LAW (RFC 9111 §5.2): directive names are case-insensitive
law cache_directive_case:
  {Cache.cache.parse("No-Store, MAX-AGE=0, Public")
    == Cache.Cc{True{}, False{}, True{}, False{}, "0", ""} : Cache.Cc}
