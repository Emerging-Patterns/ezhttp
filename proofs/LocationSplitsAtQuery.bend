# proofs of laws/LocationSplitsAtQuery.bend
import Base
import ../src/url.bend as Url
import ../src/redirect.bend as Redirect
import ../laws/LocationSplitsAtQuery.bend as Laws

def Laws.split_query(loc, p, q, e):
  %e : {Redirect.redirect.split.of(_, Url.frag.drop(loc))
    == Redirect.Ref{p, "?" ++ q} : Redirect.Ref}
  {==}

def Laws.split_plain(loc, e):
  %e : {Redirect.redirect.split.of(_, Url.frag.drop(loc))
    == Redirect.Ref{Url.frag.drop(loc), ""} : Redirect.Ref}
  {==}
