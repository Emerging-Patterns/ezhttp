# proofs of laws/ParseSchemeFirst.bend
import Base
import ../src/url.bend as Url
import ../laws/ParseSchemeFirst.bend as Laws

def Laws.parse_scheme_first(_url, h, t, e):
  %e : {Url.parse.scheme(_)
    == Url.parse.rest(String.to_lower(h), String.join(t, ":")) : Url.Loc}
  {==}
