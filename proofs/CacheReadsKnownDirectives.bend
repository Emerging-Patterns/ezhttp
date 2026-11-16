# proofs of laws/CacheReadsKnownDirectives.bend
import Base
import ../src/http.bend as Http
import ../src/cache.bend as Cache
import ../laws/CacheReadsKnownDirectives.bend as Laws

def Laws.fold_each(_h, _t, _c):
  {==}

def Laws.fold_end(_c):
  {==}

def Laws.one_no_store(c, piece, e1, e2):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == Cache.cache.store(c) : Cache.Cc}
  %e2 : {Cache.cache.one.flag(c, _) == Cache.cache.store(c) : Cache.Cc}
  {==}

def Laws.one_no_cache(c, piece, e1, e2):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == Cache.cache.revalidate(c) : Cache.Cc}
  %e2 : {Cache.cache.one.flag(c, _) == Cache.cache.revalidate(c) : Cache.Cc}
  {==}

def Laws.one_public(c, piece, e1, e2):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == Cache.cache.pub(c) : Cache.Cc}
  %e2 : {Cache.cache.one.flag(c, _) == Cache.cache.pub(c) : Cache.Cc}
  {==}

def Laws.one_private(c, piece, e1, e2):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == Cache.cache.priv(c) : Cache.Cc}
  %e2 : {Cache.cache.one.flag(c, _) == Cache.cache.priv(c) : Cache.Cc}
  {==}

def Laws.one_max_age(c, piece, _before, after, _n, e1, e2, e3):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == Cache.cache.age(c, String.trim(after)) : Cache.Cc}
  %e2 : {Cache.cache.one.store(c, _, String.trim(after), String.eq(_, "no-store"))
    == Cache.cache.age(c, String.trim(after)) : Cache.Cc}
  %e3 : {Cache.cache.one.age_ok(c, String.trim(after), _) == Cache.cache.age(c, String.trim(after))
    : Cache.Cc}
  {==}

def Laws.one_max_age_junk(c, piece, _before, after, e1, e2, e3):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == c : Cache.Cc}
  %e2 : {Cache.cache.one.store(c, _, String.trim(after), String.eq(_, "no-store")) == c : Cache.Cc}
  %e3 : {Cache.cache.one.age_ok(c, String.trim(after), _) == c : Cache.Cc}
  {==}

def Laws.one_unknown(c, piece, before, after, e1, e2, e3, e4, e5, e6):
  %e1 : {Cache.cache.one.dispatch(c, piece, _) == c : Cache.Cc}
  %e2 : {Cache.cache.one.store(c, String.to_lower(String.trim(before)), String.trim(after), _)
    == c : Cache.Cc}
  %e3 : {Cache.cache.one.cache(c, String.to_lower(String.trim(before)), String.trim(after), _)
    == c : Cache.Cc}
  %e4 : {Cache.cache.one.age(c, String.to_lower(String.trim(before)), String.trim(after), _)
    == c : Cache.Cc}
  %e5 : {Cache.cache.one.public(c, String.to_lower(String.trim(before)), String.trim(after), _)
    == c : Cache.Cc}
  %e6 : {Cache.cache.one.private(c, String.to_lower(String.trim(before)), String.trim(after), _)
    == c : Cache.Cc}
  {==}
