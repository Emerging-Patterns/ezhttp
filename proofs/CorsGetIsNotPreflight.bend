# proofs of laws/CorsGetIsNotPreflight.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsGetIsNotPreflight.bend as Laws

def Laws.cors_get_is_not_preflight(_method, _target, headers, _body, e):
  %e : {Bool.and(_, Bool.not(String.is_empty(Http.headers.find(headers,
    "access-control-request-method")))) == False{} : Bool}
  {==}
