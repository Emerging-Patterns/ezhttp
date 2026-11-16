# proofs of laws/CorsPreflightHeaderDenied.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsPreflightHeaderDenied.bend as Laws

def Laws.cors_preflight_header_denied(
  origins,
  methods,
  headers,
  credentials,
  max_age,
  _expose,
  origin,
  method,
  req_headers,
  e1,
  e2,
  e3
):
  %e1 : {Cors.cors.preflight.denied(Cors.cors.acao(origins, credentials, origin), methods, headers, credentials,
    max_age, req_headers, method, _) == Http.Reply{400, [], ""} : Http.Reply}
  %e2 : {Cors.cors.preflight.method(Cors.cors.acao(origins, credentials, origin), methods, headers, credentials,
    max_age, req_headers, method, _) == Http.Reply{400, [], ""} : Http.Reply}
  %e3 : {Cors.cors.preflight.headers(Cors.cors.acao(origins, credentials, origin), methods, headers, credentials,
    max_age, req_headers, _) == Http.Reply{400, [], ""} : Http.Reply}
  {==}
