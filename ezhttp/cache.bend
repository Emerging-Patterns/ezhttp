# ezhttp/cache: Cache-Control and a small freshness check (RFC 9111). This is
# not a shared cache. Expires is recorded; max-age overrides it for freshness.
# IMF-fixdate arithmetic is not evaluated.
import Base
import ./http.bend as Http

# the directives this module records
type Cc is Data:
  Cc{
    no_store: Bool
    no_cache: Bool
    public: Bool
    private: Bool
    max_age: String
    expires: String
  }

# no directives
def cache.empty() -> Cc:
  Cc{False{}, False{}, False{}, False{}, "", ""}

# set no-store
def cache.store(c: Cc) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{True{}, no_cache, public, private, max_age, expires}

# set no-cache
def cache.revalidate(c: Cc) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{no_store, True{}, public, private, max_age, expires}

# set public
def cache.pub(c: Cc) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{no_store, no_cache, True{}, private, max_age, expires}

# set private
def cache.priv(c: Cc) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{no_store, no_cache, public, True{}, max_age, expires}

# set max-age text
def cache.age(c: Cc, age: String) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{no_store, no_cache, public, private, age, expires}

# set the Expires header text
def cache.expires(c: Cc, when: String) -> Cc:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Cc{no_store, no_cache, public, private, max_age, when}

# private, or leave the directive unrecognized
def cache.one.private(c: Cc, _name: String, _value: String, hit: Bool) -> Cc:
  match hit:
    case True{}:
      cache.priv(c)
    case False{}:
      c

# public
def cache.one.public(c: Cc, +name: String, value: String, hit: Bool) -> Cc:
  match hit:
    case True{}:
      cache.pub(c)
    case False{}:
      cache.one.private(c, name, value, String.eq(name, "private"))

# max-age, kept only when the argument is digits (delta-seconds)
def cache.one.age_ok(c: Cc, +raw: String, m: Maybe<&2, Nat>) -> Cc:
  match m:
    case None{}:
      c
    case Some{n}:
      cache.age(c, raw)

# max-age
def cache.one.age(c: Cc, +name: String, +value: String, hit: Bool) -> Cc:
  match hit:
    case True{}:
      cache.one.age_ok(c, value, Http.digits.read(value))
    case False{}:
      cache.one.public(c, name, value, String.eq(name, "public"))

# no-cache
def cache.one.cache(c: Cc, +name: String, +value: String, hit: Bool) -> Cc:
  match hit:
    case True{}:
      cache.revalidate(c)
    case False{}:
      cache.one.age(c, name, value, String.eq(name, "max-age"))

# no-store
def cache.one.store(c: Cc, +name: String, +value: String, hit: Bool) -> Cc:
  match hit:
    case True{}:
      cache.store(c)
    case False{}:
      cache.one.cache(c, name, value, String.eq(name, "no-cache"))

# a directive with no `=` argument
def cache.one.flag(c: Cc, +name: String) -> Cc:
  cache.one.store(c, name, "", String.eq(name, "no-store"))

# flag or name=value
def cache.one.dispatch(c: Cc, +piece: String, cut: Http.Cut) -> Cc:
  match cut:
    case Http.NoCut{}:
      cache.one.flag(c, String.to_lower(String.trim(piece)))
    case Http.Cut{+before, after}:
      +name = String.to_lower(String.trim(before))
      cache.one.store(c, name, String.trim(after), String.eq(name, "no-store"))

# one directive text
def cache.one(c: Cc, +piece: String) -> Cc:
  cache.one.dispatch(c, piece, Http.divide(piece, "="))

# walk directives. The list shrinks.
def cache.fold(ps: List<&2, String>, c: Cc) -> Cc:
  match ps:
    case []:
      c
    case h <> t:
      cache.fold(t, cache.one(c, String.trim(h)))

# Cache-Control field value (RFC 9111 §5.2)
def cache.parse(value: String) -> Cc:
  cache.fold(String.split(value, ','), cache.empty())

# record an Expires header beside Cache-Control (RFC 9111 §5.3)
def cache.note(value: String, expires: String) -> Cc:
  cache.expires(cache.parse(value), expires)

# true when max-age is present, so it overrides Expires (RFC 9111 §4.2.1)
def cache.max_age(c: Cc) -> Bool:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      Bool.not(String.eq(max_age, ""))

# freshness from max-age. no-store and no-cache are not fresh.
def cache.fresh.go(age: Nat, m: Maybe<&2, Nat>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{n}:
      Nat.is_lt(age, n)

# no-cache must revalidate
def cache.fresh.cache(age: Nat, max_age: String, no_cache: Bool) -> Bool:
  match no_cache:
    case True{}:
      False{}
    case False{}:
      cache.fresh.go(age, Http.digits.read(max_age))

# no-store is not reused
def cache.fresh.store(age: Nat, no_cache: Bool, max_age: String, no_store: Bool)
  -> Bool:
  match no_store:
    case True{}:
      False{}
    case False{}:
      cache.fresh.cache(age, max_age, no_cache)

# age seconds against the directives. max-age=0 is stale (RFC 9111 §4.2.1).
def cache.fresh(c: Cc, age: Nat) -> Bool:
  match c:
    case Cc{no_store, no_cache, public, private, max_age, expires}:
      cache.fresh.store(age, no_cache, max_age, no_store)
