import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Access-Control-Request-Headers names the headers
law cors_request_headers_header:
  {Cors.cors.request_headers("Content-Type")
    == Http.H{"Access-Control-Request-Headers", "Content-Type"} : Http.Header}
