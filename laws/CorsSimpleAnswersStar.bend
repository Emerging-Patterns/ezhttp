import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): `*` without credentials is the only ACAO header
law cors_simple_star:
  {Cors.cors.simple(Cors.Cfg{["*"], ["GET"], [], False{}, "", []},
      "https://app.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [Http.H{"Access-Control-Allow-Origin", "*"}], "ok"}
    : Http.Reply}
