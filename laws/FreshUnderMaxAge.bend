# For every age and every directive state with neither no-store nor
# no-cache whose max-age argument reads as delta-seconds `n`, the response
# is fresh exactly when its age is under `n` (`cache.fresh`): fresh below
# max-age, stale at it and after it (so max-age=0 is always stale), whatever
# public, private and the recorded Expires say (max-age overrides Expires).
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): fresh exactly while the age is under max-age
law fresh_max_age:
  for public: Bool
  for private: Bool
  for max_age: String
  for expires: String
  for n: Nat
  for age: Nat
  for e: {Some{n} == Http.digits.read(max_age) : Maybe<&2, Nat>}
  {Cache.cache.fresh(Cache.Cc{False{}, False{}, public, private, max_age,
    expires}, age) == Nat.is_lt(age, n) : Bool}
