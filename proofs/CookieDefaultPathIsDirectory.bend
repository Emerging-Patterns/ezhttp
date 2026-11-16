# proofs of laws/CookieDefaultPathIsDirectory.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieDefaultPathIsDirectory.bend as Laws

def Laws.cookie_default_path_dir(p, e):
  %e : {Cookie.cookie.default_of(p, _) == Cookie.cookie.before(p) : String}
  {==}

def Laws.cookie_before(_p):
  {==}
