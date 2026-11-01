# proofs of laws/NoStoreNeverFresh.bend
import Base
import ../laws/NoStoreNeverFresh.bend as Laws

# fresh_no_store_any: fresh matches no-store first
def Laws.fresh_no_store_any(
  _no_cache,
  _public,
  _private,
  _max_age,
  _expires,
  _age
):
  {==}
