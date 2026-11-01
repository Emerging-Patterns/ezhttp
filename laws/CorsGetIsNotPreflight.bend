import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a GET with no Access-Control-Request-Method is not a preflight
law cors_get_is_not_preflight:
  {Cors.cors.is_preflight(Http.Request{"GET", "/",
      [Http.H{"Origin", "https://a"}], ""}) == False{} : Bool}
