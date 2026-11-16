# proofs of laws/CorsPreflightOriginDenied.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsPreflightOriginDenied.bend as Laws

def Laws.cors_preflight_origin_denied(
  origins,
  methods,
  headers,
  credentials,
  max_age,
  _expose,
  origin,
  method,
  req_headers,
  e
):
  %e : {Cors.cors.preflight.denied(Cors.cors.acao.ok(origins, credentials, origin, _),
    methods, headers, credentials, max_age, req_headers, method,
    String.is_empty(Cors.cors.acao.ok(origins, credentials, origin, _)))
    == Http.Reply{400, [], ""} : Http.Reply}
  {==}
