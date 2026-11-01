# proofs of laws/FreshNoCacheAny.bend
import Base
import ../laws/FreshNoCacheAny.bend as Laws

# fresh_no_cache_any: no-store either way, then no-cache
def Laws.fresh_no_cache_any(
  no_store,
  _public,
  _private,
  _max_age,
  _expires,
  _age
):
  match no_store:
    case False{}:
      {==}
    case True{}:
      {==}
