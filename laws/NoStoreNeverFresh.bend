import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2.2.5): whatever else they say, directives with no-store
# are never fresh
law fresh_no_store_any:
  for no_cache: Bool
  for public: Bool
  for private: Bool
  for max_age: String
  for expires: String
  for age: Nat
  {Cache.cache.fresh(Cache.Cc{True{}, no_cache, public, private, max_age,
    expires}, age) == False{} : Bool}
