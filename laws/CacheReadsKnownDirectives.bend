# For every directive state `c` read so far and every directive text
# `piece`, Cache-Control is read one directive at a time, left to right,
# each over what the ones before it recorded (`cache.fold`). A directive with
# no `=` whose name, trimmed and in any case, is no-store, no-cache, public
# or private sets that flag and keeps the rest. A `max-age=` directive whose
# name is max-age in any case records its trimmed argument when that is
# delta-seconds and is ignored otherwise. A `name=value` directive with any
# other name is ignored (RFC 9111 §5.2: names are case-insensitive and
# unrecognized directives are ignored).
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache

# LAW (RFC 9111 §5.2): directives are read left to right
law fold_each:
  for h: String
  for t: List<&2, String>
  for c: Cache.Cc
  {Cache.cache.fold(h <> t, c) == Cache.cache.fold(t, Cache.cache.one(c, String.trim(h)))
    : Cache.Cc}

# LAW (RFC 9111 §5.2): after the last directive, what was read is the result
law fold_end:
  for c: Cache.Cc
  {Cache.cache.fold([], c) == c : Cache.Cc}

# LAW (RFC 9111 §5.2.2.5): no-store, in any case, sets no-store
law one_no_store:
  for c: Cache.Cc
  for +piece: String
  for e1: {Http.NoCut{} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"no-store" == String.to_lower(String.trim(piece)) : String}
  {Cache.cache.one(c, piece) == Cache.cache.store(c) : Cache.Cc}

# LAW (RFC 9111 §5.2.2.4): no-cache, in any case, sets no-cache
law one_no_cache:
  for c: Cache.Cc
  for +piece: String
  for e1: {Http.NoCut{} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"no-cache" == String.to_lower(String.trim(piece)) : String}
  {Cache.cache.one(c, piece) == Cache.cache.revalidate(c) : Cache.Cc}

# LAW (RFC 9111 §5.2.2.9): public, in any case, sets public
law one_public:
  for c: Cache.Cc
  for +piece: String
  for e1: {Http.NoCut{} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"public" == String.to_lower(String.trim(piece)) : String}
  {Cache.cache.one(c, piece) == Cache.cache.pub(c) : Cache.Cc}

# LAW (RFC 9111 §5.2.2.7): private, in any case, sets private
law one_private:
  for c: Cache.Cc
  for +piece: String
  for e1: {Http.NoCut{} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"private" == String.to_lower(String.trim(piece)) : String}
  {Cache.cache.one(c, piece) == Cache.cache.priv(c) : Cache.Cc}

# LAW (RFC 9111 §5.2.2.1): max-age, in any case, records delta-seconds
law one_max_age:
  for c: Cache.Cc
  for +piece: String
  for +before: String
  for +after: String
  for n: Nat
  for e1: {Http.Cut{before, after} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"max-age" == String.to_lower(String.trim(before)) : String}
  for e3: {Some{n} == Http.digits.read(String.trim(after)) : Maybe<&2, Nat>}
  {Cache.cache.one(c, piece) == Cache.cache.age(c, String.trim(after)) : Cache.Cc}

# LAW (RFC 9111 §5.2.1.1): a max-age argument that is not delta-seconds is
# ignored
law one_max_age_junk:
  for c: Cache.Cc
  for +piece: String
  for +before: String
  for +after: String
  for e1: {Http.Cut{before, after} == Http.divide(piece, "=") : Http.Cut}
  for e2: {"max-age" == String.to_lower(String.trim(before)) : String}
  for e3: {None{} == Http.digits.read(String.trim(after)) : Maybe<&2, Nat>}
  {Cache.cache.one(c, piece) == c : Cache.Cc}

# LAW (RFC 9111 §5.2): a name=value directive of no recorded name is ignored
law one_unknown:
  for c: Cache.Cc
  for +piece: String
  for +before: String
  for +after: String
  for e1: {Http.Cut{before, after} == Http.divide(piece, "=") : Http.Cut}
  for e2: {False{} == String.eq(String.to_lower(String.trim(before)), "no-store") : Bool}
  for e3: {False{} == String.eq(String.to_lower(String.trim(before)), "no-cache") : Bool}
  for e4: {False{} == String.eq(String.to_lower(String.trim(before)), "max-age") : Bool}
  for e5: {False{} == String.eq(String.to_lower(String.trim(before)), "public") : Bool}
  for e6: {False{} == String.eq(String.to_lower(String.trim(before)), "private") : Bool}
  {Cache.cache.one(c, piece) == c : Cache.Cc}
