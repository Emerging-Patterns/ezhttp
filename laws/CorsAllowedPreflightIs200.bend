import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): an allowed preflight is 200 with the CORS headers
law cors_preflight_allowed:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", "PUT", "Content-Type")
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "GET, PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "600"}
    ], ""} : Http.Reply}
