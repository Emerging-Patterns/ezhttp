import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): only an OPTIONS request is a preflight; any other method is
# not, whatever its target, headers and body
law cors_get_is_not_preflight:
  for +method: String
  for target: String
  for +headers: List<&2, Http.Header>
  for body: String
  for e: {False{} == String.eq(method, "OPTIONS") : Bool}
  {Cors.cors.is_preflight(Http.Request{method, target, headers, body})
    == False{} : Bool}
