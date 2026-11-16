import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a preflight from an origin the allow-list does not allow is
# 400, whatever the method and requested headers
law cors_preflight_origin_denied:
  for +origins: List<&2, String>
  for +methods: List<&2, String>
  for +headers: List<&2, String>
  for +credentials: Bool
  for max_age: String
  for expose: List<&2, String>
  for +origin: String
  for +method: String
  for +req_headers: String
  for e: {False{} == Cors.cors.allowed(origins, origin) : Bool}
  {Cors.cors.preflight(Cors.Cfg{origins, methods, headers, credentials, max_age,
      expose}, origin, method, req_headers)
    == Http.Reply{400, [], ""} : Http.Reply}
