# proofs of laws/CorsAllowListReflectsOrigin.bend
import Base
import ../src/cors.bend as Cors
import ../laws/CorsAllowListReflectsOrigin.bend as Laws

def Laws.cors_explicit_origin(os, origin, e1, e2):
  %e1 : {Cors.cors.acao.ok(os, False{}, origin, Bool.or(_, Cors.cors.hit(origin, os)))
    == origin : String}
  %e2 : {Cors.cors.acao.ok(os, False{}, origin, _) == origin : String}
  %e1 : {Cors.cors.acao.star(origin, _) == origin : String}
  {==}
