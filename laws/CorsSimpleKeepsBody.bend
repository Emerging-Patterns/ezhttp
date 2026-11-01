import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a simple response keeps its body and gains CORS headers
law cors_simple_reflects:
  {Cors.cors.simple(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      "https://app.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Expose-Headers", "X-Trace"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"}
    ], "ok"} : Http.Reply}
