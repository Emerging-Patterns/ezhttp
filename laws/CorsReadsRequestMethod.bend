import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Access-Control-Request-Method carries the method as given
law cors_request_method_header:
  for method: String
  {Cors.cors.request_method(method)
    == Http.H{"Access-Control-Request-Method", method} : Http.Header}
