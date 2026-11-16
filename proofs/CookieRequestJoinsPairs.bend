# proofs of laws/CookieRequestJoinsPairs.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieRequestJoinsPairs.bend as Laws

def Laws.cookie_join(_cs):
  {==}

def Laws.cookie_pairs_nil(_cs, e):
  %e : {Cookie.cookie.pairs(_) == [] : List<&2, String>}
  {==}

def Laws.cookie_pairs_kept(name, value, _x, _m, _d, _p, _s, _h, _ss, _ho, t, e):
  %e : {Cookie.cookie.pairs.keep(name, value, _, _u => Cookie.cookie.pairs(t))
    == (name ++ "=" ++ value) <> Cookie.cookie.pairs(t) : List<&2, String>}
  {==}

def Laws.cookie_pairs_dropped(name, value, _x, _m, _d, _p, _s, _h, _ss, _ho, t, e):
  %e : {Cookie.cookie.pairs.keep(name, value, _, _u => Cookie.cookie.pairs(t))
    == Cookie.cookie.pairs(t) : List<&2, String>}
  {==}
