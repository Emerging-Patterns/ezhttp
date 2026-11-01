import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): an explicit allow-list reflects the matching origin
law cors_explicit_origin:
  {Cors.cors.acao(["https://app.example"], False{}, "https://app.example")
    == "https://app.example" : String}
