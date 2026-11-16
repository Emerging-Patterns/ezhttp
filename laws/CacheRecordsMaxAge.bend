# For every directive state and every max-age argument that is
# delta-seconds, recording it (`cache.age`, what a max-age directive does,
# laws/CacheReadsKnownDirectives.bend) leaves max-age present
# (`cache.max_age`), so it is what freshness uses and it overrides Expires.
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): a recorded max-age is present
law cache_max_age_present:
  for c: Cache.Cc
  for raw: String
  for n: Nat
  for e: {Some{n} == Http.digits.read(raw) : Maybe<&2, Nat>}
  {Cache.cache.max_age(Cache.cache.age(c, raw)) == True{} : Bool}
