import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): OPTIONS plus Access-Control-Request-Method is a preflight
law cors_on_preflight:
  {Cors.cors.on(Cors.Cfg{["https://app.example"], ["GET", "PUT"],
      ["Content-Type"], True{}, "600", ["X-Trace"]},
      Http.Request{"OPTIONS", "/", [
        Http.H{"Origin", "https://app.example"},
        Http.H{"Access-Control-Request-Method", "PUT"},
        Http.H{"Access-Control-Request-Headers", "Content-Type"}
      ], ""}, Http.Reply{200, [], "nope"})
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Credentials", "true"},
      Http.H{"Vary", "Origin"},
      Http.H{"Access-Control-Allow-Origin", "https://app.example"},
      Http.H{"Access-Control-Allow-Methods", "GET, PUT"},
      Http.H{"Access-Control-Allow-Headers", "Content-Type"},
      Http.H{"Access-Control-Max-Age", "600"}
    ], ""} : Http.Reply}
