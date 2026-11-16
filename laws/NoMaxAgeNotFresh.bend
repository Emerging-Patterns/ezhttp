# For every age and every directive state whose max-age argument does not
# read as delta-seconds (none was given, or it was not digits), the response
# is not fresh (`cache.fresh`), whatever else the directives and the
# recorded Expires say: without max-age nothing is treated as fresh.
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache

# LAW (RFC 9111 §4.2.1): without max-age the response is not fresh
law fresh_without_max_age:
  for no_store: Bool
  for no_cache: Bool
  for public: Bool
  for private: Bool
  for max_age: String
  for expires: String
  for age: Nat
  for e: {None{} == Http.digits.read(max_age) : Maybe<&2, Nat>}
  {Cache.cache.fresh(Cache.Cc{no_store, no_cache, public, private, max_age,
    expires}, age) == False{} : Bool}
