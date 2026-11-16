import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Origin is the request header of that name, for any origin
law cors_origin_header:
  for origin: String
  {Cors.cors.origin(origin) == Http.H{"Origin", origin} : Http.Header}
