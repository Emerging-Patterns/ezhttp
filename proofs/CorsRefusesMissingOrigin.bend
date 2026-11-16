# proofs of laws/CorsRefusesMissingOrigin.bend
import Base
import ../src/cors.bend as Cors
import ../laws/CorsRefusesMissingOrigin.bend as Laws

def Laws.cors_refused_origin(os, credentials, origin, e):
  %e : {Cors.cors.acao.ok(os, credentials, origin, _) == "" : String}
  {==}
