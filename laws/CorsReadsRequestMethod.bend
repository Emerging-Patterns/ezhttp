import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Access-Control-Request-Method names the method
law cors_request_method_header:
  {Cors.cors.request_method("PUT")
    == Http.H{"Access-Control-Request-Method", "PUT"} : Http.Header}
