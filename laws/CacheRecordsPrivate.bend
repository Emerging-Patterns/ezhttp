import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.6): private alone is recorded
law cache_private_alone:
  {Cache.cache.parse("private")
    == Cache.Cc{False{}, False{}, False{}, True{}, "", ""} : Cache.Cc}
