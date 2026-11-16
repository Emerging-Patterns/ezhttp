# proofs of laws/CorsVaryOnSpecificOrigin.bend
import Base
import ../laws/CorsVaryOnSpecificOrigin.bend as Laws

def Laws.cors_vary_specific(acao, e1, e2):
  %e1 : {Bool.and(Bool.not(_), Bool.not(String.is_empty(acao))) == True{} : Bool}
  %e2 : {Bool.and(True{}, Bool.not(_)) == True{} : Bool}
  {==}
