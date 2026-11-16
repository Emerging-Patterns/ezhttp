# proofs of laws/CookieLongerPathFails.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieLongerPathFails.bend as Laws

def Laws.cookie_path_not_prefix(req, cpath, e):
  %e : {Cookie.cookie.path_prefix(req, cpath, _) == False{} : Bool}
  {==}
