# proofs of laws/CookiePathNeedsSegmentBoundary.bend
import Base
import ../src/cookie.bend as Cookie
import ../laws/CookiePathNeedsSegmentBoundary.bend as Laws

def Laws.cookie_path_not_boundary(req, cpath, e1, e2, e3, e4):
  %e1 : {Cookie.cookie.path_prefix(req, cpath, _) == False{} : Bool}
  %e2 : {Cookie.cookie.path_rest(req, cpath, _) == False{} : Bool}
  %e3 : {Cookie.cookie.path_slash(req, cpath, _) == False{} : Bool}
  Equal.sym(Bool, False{},
    String.starts_with(String.drop(req, String.length(cpath)), "/"), e4)
