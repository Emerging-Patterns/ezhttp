import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a refused origin leaves the handler reply unchanged
law cors_simple_refused:
  {Cors.cors.simple(Cors.Cfg{["https://ok.example"], [], [], False{}, "", []},
      "https://no.example", Http.Reply{200, [], "ok"})
    == Http.Reply{200, [], "ok"} : Http.Reply}
