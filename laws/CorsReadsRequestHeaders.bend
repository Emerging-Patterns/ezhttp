import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Access-Control-Request-Headers carries the names as given
law cors_request_headers_header:
  for names: String
  {Cors.cors.request_headers(names)
    == Http.H{"Access-Control-Request-Headers", names} : Http.Header}
