import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a method outside the allow-list is a failed preflight
law cors_preflight_method_denied:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", "DELETE", "")
    == Http.Reply{400, [], ""} : Http.Reply}
