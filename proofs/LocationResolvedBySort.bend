# proofs of laws/LocationResolvedBySort.bend
import Base
import ../src/redirect.bend as Redirect
import ../laws/LocationResolvedBySort.bend as Laws

def Laws.target_against(url, loc, e1, scheme, host, port, path, e2):
  %e1 : {Redirect.redirect.target.of(url, loc, _)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}
  %e2 : {Redirect.redirect.at(_, loc)
    == Redirect.redirect.against(scheme, host, port, path, loc,
      Redirect.redirect.sort(loc)) : Maybe<&2, String>}
  {==}
