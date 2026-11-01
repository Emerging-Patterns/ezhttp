import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a preflight whose origin is not allowed is 400
law cors_preflight_origin_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://no.example", "PUT", "")
    == Http.Reply{400, [], ""} : Http.Reply}
