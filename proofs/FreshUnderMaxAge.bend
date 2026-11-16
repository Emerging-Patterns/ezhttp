# proofs of laws/FreshUnderMaxAge.bend
import Base
import ../src/cache.bend as Cache
import ../laws/FreshUnderMaxAge.bend as Laws

def Laws.fresh_max_age(_public, _private, _max_age, _expires, n, age, e):
  %e : {Cache.cache.fresh.go(age, _) == Nat.is_lt(age, n) : Bool}
  {==}
