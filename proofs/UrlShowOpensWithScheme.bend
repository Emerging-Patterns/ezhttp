# proofs of laws/UrlShowOpensWithScheme.bend
import Base
import ../laws/UrlShowOpensWithScheme.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.url_show_opens_with_scheme(scheme, host, port, path):
  M1.eq.starts_append(scheme, " " ++ host ++ " " ++ U32.show(port) ++ " " ++ path)
