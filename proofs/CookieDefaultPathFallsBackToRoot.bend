# proofs of laws/CookieDefaultPathFallsBackToRoot.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieDefaultPathFallsBackToRoot.bend as Laws

def Laws.cookie_default_path_root(p, e):
  %e : {Cookie.cookie.default_of(p, _) == "/" : String}
  {==}
