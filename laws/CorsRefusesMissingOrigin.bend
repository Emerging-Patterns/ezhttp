import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): a missing origin is refused
law cors_refused_origin:
  {Cors.cors.acao(["https://ok.example"], False{}, "https://no.example")
    == "" : String}
