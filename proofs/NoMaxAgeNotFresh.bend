# proofs of laws/NoMaxAgeNotFresh.bend
import Base
import ../src/cache.bend as Cache
import ../laws/NoMaxAgeNotFresh.bend as Laws

# no-store and no-cache are not fresh either way; past them, max-age decides
def Laws.fresh_without_max_age(
  no_store,
  no_cache,
  _public,
  _private,
  _max_age,
  _expires,
  age,
  e
):
  match no_store:
    case True{}:
      {==}
    case False{}:
      match no_cache:
        case True{}:
          {==}
        case False{}:
          %e : {Cache.cache.fresh.go(age, _) == False{} : Bool}
          {==}
