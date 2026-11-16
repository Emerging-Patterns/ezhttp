# proofs of laws/CacheRecordsMaxAge.bend
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache
import ../laws/CacheRecordsMaxAge.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

# whether a read is some number
def cm.some(m: Maybe<&2, Nat>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{k}:
      True{}

# a recorded argument is not empty, since digits.read of "" is none
def Laws.cache_max_age_present(c, raw, n, e):
  match c:
    case Cache.Cc{no_store, no_cache, public, private, max_age, expires}:
      match raw:
        case SNil{}:
          M1.eq.bit.absurd(&2, {Cache.cache.max_age(Cache.cache.age(Cache.Cc{no_store,
            no_cache, public, private, max_age, expires}, "")) == True{} : Bool},
            Equal.sym(Bool, True{}, False{},
              Equal.cong(Maybe<&2, Nat>, Bool, cm.some, Some{n}, None{}, e)))
        case SCon{h, t}:
          {==}
