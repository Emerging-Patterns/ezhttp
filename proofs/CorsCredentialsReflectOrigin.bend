# proofs of laws/CorsCredentialsReflectOrigin.bend
import Base
import ../src/cors.bend as Cors
import ../laws/CorsCredentialsReflectOrigin.bend as Laws

def Laws.cors_credentials_reflect_origin(os, origin, e):
  %e : {Cors.cors.acao.ok(os, True{}, origin, _) == origin : String}
  {==}
