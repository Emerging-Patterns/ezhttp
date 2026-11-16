# For every Cache-Control value and Expires text, the directives noted with
# an Expires header (`cache.note`) are exactly the directives read from the
# Cache-Control value, with that Expires text recorded beside them; noting
# Expires changes no directive.
import Base
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.3): Expires is recorded beside Cache-Control
law cache_note_expires:
  for value: String
  for when: String
  for no_store: Bool
  for no_cache: Bool
  for public: Bool
  for private: Bool
  for max_age: String
  for expires: String
  for e: {Cache.Cc{no_store, no_cache, public, private, max_age, expires}
    == Cache.cache.parse(value) : Cache.Cc}
  {Cache.cache.note(value, when)
    == Cache.Cc{no_store, no_cache, public, private, max_age, when} : Cache.Cc}
