# proofs of laws/CookieIdenticalPathsMatch.bend
import Base
import ../src/cookie.bend as Cookie
import ./lemmas/CookieStrings.bend as CS
import ../laws/CookieIdenticalPathsMatch.bend as Laws

def Laws.cookie_path_identical(p):
  %Equal.sym(Bool, String.starts_with(p, p), True{}, CS.starts_self(p))
    : {Cookie.cookie.path_prefix(p, p, _) == True{} : Bool}
  %Equal.sym(Cmp, String.order(p, p), EQ{}, CS.order_self(p))
    : {Cookie.cookie.path_rest(p, p, Cmp.is_eq(_)) == True{} : Bool}
  {==}
