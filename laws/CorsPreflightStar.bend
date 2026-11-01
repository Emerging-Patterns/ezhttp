import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): `*` without credentials is ACAO on a successful preflight
law cors_preflight_star:
  {Cors.cors.preflight(Cors.Cfg{["*"], ["GET"], [], False{}, "0", []},
      "https://a", "GET", "")
    == Http.Reply{200, [
      Http.H{"Access-Control-Allow-Origin", "*"},
      Http.H{"Access-Control-Allow-Methods", "GET"},
      Http.H{"Access-Control-Allow-Headers", ""},
      Http.H{"Access-Control-Max-Age", "0"}
    ], ""} : Http.Reply}
