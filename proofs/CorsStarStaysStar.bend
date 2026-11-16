# proofs of laws/CorsStarStaysStar.bend
import Base
import ../src/cors.bend as Cors
import ../laws/CorsStarStaysStar.bend as Laws

def Laws.cors_star_without_credentials(os, origin, e):
  %e : {Cors.cors.acao.ok(os, False{}, origin, Bool.or(_, Cors.cors.hit(origin, os)))
    == "*" : String}
  %e : {Cors.cors.acao.star(origin, _) == "*" : String}
  {==}
