# proofs of laws/CorsSimpleKeepsBody.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsSimpleKeepsBody.bend as Laws

def Laws.cors_simple_reflects(
  origins,
  _methods,
  _headers,
  credentials,
  _max_age,
  expose,
  origin,
  status,
  hs,
  body,
  e
):
  %e : {Cors.cors.simple.add(Http.Reply{status, hs, body}, Cors.cors.acao(origins, credentials, origin), credentials,
    expose, Bool.not(_)) == Http.Reply{status, List.append(&2, Http.Header,
      Cors.cors.simple_hs(Cors.cors.acao(origins, credentials, origin), credentials, expose), hs), body} : Http.Reply}
  {==}
