import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Origin is the request header of that name
law cors_origin_header:
  {Cors.cors.origin("https://app.example")
    == Http.H{"Origin", "https://app.example"} : Http.Header}
