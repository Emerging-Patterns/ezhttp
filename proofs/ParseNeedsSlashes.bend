# proofs of laws/ParseNeedsSlashes.bend
import Base
import ../src/url.bend as Url
import ../laws/ParseNeedsSlashes.bend as Laws

def Laws.parse_needs_slashes(scheme, rest, e):
  %e : {Url.parse.body(scheme, rest, _)
    == Url.Bad{scheme ++ ":" ++ rest ++ " has no //"}
    : Url.Loc}
  {==}
