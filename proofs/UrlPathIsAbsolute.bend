# proofs of laws/UrlPathIsAbsolute.bend
import Base
import ../laws/UrlPathIsAbsolute.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.path_absolute(ps):
  match ps:
    case []:
      {==}
    case h <> t:
      M1.eq.starts_nil(String.join(t, "/"))
