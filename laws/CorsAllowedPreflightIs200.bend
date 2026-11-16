import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a preflight from an allowed origin, with an allowed method
# and only allowed headers, is 200 with the preflight headers for its ACAO
# (credentials, Vary, Allow-Origin, Allow-Methods, Allow-Headers, Max-Age)
law cors_preflight_allowed:
  for +origins: List<&2, String>
  for +methods: List<&2, String>
  for +headers: List<&2, String>
  for +credentials: Bool
  for max_age: String
  for expose: List<&2, String>
  for +origin: String
  for +method: String
  for +req_headers: String
  for +e1: {False{} == String.is_empty(Cors.cors.acao(origins, credentials, origin)) : Bool}
  for e2: {True{} == Cors.cors.hit(method, methods) : Bool}
  for e3: {True{} == Cors.cors.headers_ok(req_headers, headers) : Bool}
  {Cors.cors.preflight(Cors.Cfg{origins, methods, headers, credentials, max_age,
      expose}, origin, method, req_headers)
    == Http.Reply{200, Cors.cors.preflight_hs(Cors.cors.acao(origins, credentials, origin), methods,
      headers, credentials, max_age), ""} : Http.Reply}
