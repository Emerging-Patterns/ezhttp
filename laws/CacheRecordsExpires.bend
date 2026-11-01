import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.3): Expires is recorded beside Cache-Control
law cache_note_expires:
  {Cache.cache.note("max-age=0", "Wed, 21 Oct 2099 07:28:00 GMT")
    == Cache.Cc{False{}, False{}, False{}, False{}, "0",
      "Wed, 21 Oct 2099 07:28:00 GMT"} : Cache.Cc}
