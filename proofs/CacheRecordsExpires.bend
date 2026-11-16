# proofs of laws/CacheRecordsExpires.bend
import Base
import ../src/cache.bend as Cache
import ../laws/CacheRecordsExpires.bend as Laws

def Laws.cache_note_expires(
  _value,
  when,
  no_store,
  no_cache,
  public,
  private,
  max_age,
  _expires,
  e
):
  %e : {Cache.cache.expires(_, when)
    == Cache.Cc{no_store, no_cache, public, private, max_age, when} : Cache.Cc}
  {==}
