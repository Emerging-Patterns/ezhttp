import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): without credentials, `*` stays `*`
law cors_star_without_credentials:
  {Cors.cors.acao(["*"], False{}, "https://app.example") == "*" : String}
