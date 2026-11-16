import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): an OPTIONS request with a non-empty
# Access-Control-Request-Method is answered by the preflight for its Origin,
# requested method and requested headers, whatever the handler's reply
law cors_on_preflight:
  for cfg: Cors.Cfg
  for target: String
  for +headers: List<&2, Http.Header>
  for body: String
  for reply: Http.Reply
  for e: {False{} == String.is_empty(Http.headers.find(headers,
    "access-control-request-method")) : Bool}
  {Cors.cors.on(cfg, Http.Request{"OPTIONS", target, headers, body}, reply)
    == Cors.cors.preflight(cfg, Http.headers.find(headers, "origin"),
      Http.headers.find(headers, "access-control-request-method"),
      Http.headers.find(headers, "access-control-request-headers"))
    : Http.Reply}
