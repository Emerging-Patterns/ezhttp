import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a requested header outside the allow-list fails preflight
law cors_preflight_header_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://app.example", "PUT", "X-Nope")
    == Http.Reply{400, [], ""} : Http.Reply}
