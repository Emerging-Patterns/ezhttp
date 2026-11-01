import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.4): whatever else they say, directives with no-cache
# are never fresh
law fresh_no_cache_any:
  for no_store: Bool
  for public: Bool
  for private: Bool
  for max_age: String
  for expires: String
  for age: Nat
  {Cache.cache.fresh(Cache.Cc{no_store, True{}, public, private, max_age,
    expires}, age) == False{} : Bool}
