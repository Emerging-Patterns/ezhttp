# proofs of laws/CorsOptionsWithMethodIsPreflight.bend
import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors
import ../laws/CorsOptionsWithMethodIsPreflight.bend as Laws

def Laws.cors_on_preflight(cfg, target, headers, body, reply, e):
  %e : {Cors.cors.route(cfg, Http.Request{"OPTIONS", target, headers, body}, reply,
    Bool.and(String.eq("OPTIONS", "OPTIONS"), Bool.not(_)))
    == Cors.cors.preflight(cfg, Http.headers.find(headers, "origin"),
      Http.headers.find(headers, "access-control-request-method"),
      Http.headers.find(headers, "access-control-request-headers"))
    : Http.Reply}
  {==}
