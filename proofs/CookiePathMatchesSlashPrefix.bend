# proofs of laws/CookiePathMatchesSlashPrefix.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookiePathMatchesSlashPrefix.bend as Laws

# the third rule whatever the other tests give
def boundary.slash(
  +req: String,
  +cpath: String,
  slash: Bool,
  e2: {True{} == String.starts_with(String.drop(req, String.length(cpath)), "/") : Bool}
) -> {Cookie.cookie.path_slash(req, cpath, slash) == True{} : Bool}:
  match slash:
    case True{}:
      {==}
    case False{}:
      Equal.sym(Bool, True{},
        String.starts_with(String.drop(req, String.length(cpath)), "/"), e2)

# the third rule whatever the identity test gives
def boundary.rest(
  +req: String,
  +cpath: String,
  same: Bool,
  e2: {True{} == String.starts_with(String.drop(req, String.length(cpath)), "/") : Bool}
) -> {Cookie.cookie.path_rest(req, cpath, same) == True{} : Bool}:
  match same:
    case True{}:
      {==}
    case False{}:
      boundary.slash(req, cpath, String.ends_with(cpath, "/"), e2)

def Laws.cookie_path_prefix(req, cpath, e1, e2):
  %e1 : {Cookie.cookie.path_prefix(req, cpath, _) == True{} : Bool}
  boundary.rest(req, cpath, String.eq(req, cpath), e2)
