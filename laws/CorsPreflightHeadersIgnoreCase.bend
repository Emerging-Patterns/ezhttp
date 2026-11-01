import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): requested header names are matched case-insensitively
law cors_preflight_header_case:
  {Cors.cors.preflight(Cors.Cfg{["https://app.example"], ["PUT"],
      ["Content-Type"], False{}, "10", []},
      "https://app.example", "PUT", "content-type")
    == Http.Reply{200, [
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "10"}
    ], ""} : Http.Reply}
