# proofs of laws/CorsRefusedLeavesReply.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsRefusedLeavesReply.bend as Laws

def Laws.cors_simple_refused(
  origins,
  _methods,
  _headers,
  credentials,
  _max_age,
  expose,
  origin,
  reply,
  e
):
  %e : {Cors.cors.simple.add(reply, Cors.cors.acao(origins, credentials, origin), credentials, expose,
    Bool.not(_)) == reply : Http.Reply}
  {==}
