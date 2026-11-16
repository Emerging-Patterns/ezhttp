# proofs of laws/CorsNoVaryForStar.bend
import Base
import ../laws/CorsNoVaryForStar.bend as Laws

def Laws.cors_vary_star(acao, e):
  %e : {Bool.and(Bool.not(_), Bool.not(String.is_empty(acao))) == False{} : Bool}
  {==}
