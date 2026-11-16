# proofs of laws/CookieSlashEndedPathIsPrefix.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookieSlashEndedPathIsPrefix.bend as Laws

# the second rule whatever the identity test gives
def slash.rest(
  +req: String,
  +cpath: String,
  same: Bool,
  e2: {True{} == String.ends_with(cpath, "/") : Bool}
) -> {Cookie.cookie.path_rest(req, cpath, same) == True{} : Bool}:
  match same:
    case True{}:
      {==}
    case False{}:
      %e2 : {Cookie.cookie.path_slash(req, cpath, _) == True{} : Bool}
      {==}

def Laws.cookie_path_slash_prefix(req, cpath, e1, e2):
  %e1 : {Cookie.cookie.path_prefix(req, cpath, _) == True{} : Bool}
  slash.rest(req, cpath, String.eq(req, cpath), e2)
