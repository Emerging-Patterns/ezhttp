# proofs of laws/CorsNoVaryWhenRefused.bend
import Base
import ../laws/CorsNoVaryWhenRefused.bend as Laws
import ./lemmas/CorsBool.bend as M

def Laws.cors_vary_empty(acao, e):
  %e : {Bool.and(Bool.not(String.eq(acao, "*")), Bool.not(_)) == False{} : Bool}
  M.and_false(Bool.not(String.eq(acao, "*")))
