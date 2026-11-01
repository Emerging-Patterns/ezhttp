import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): credentials with an explicit origin still reflect it
law cors_credentials_explicit_origin:
  {Cors.cors.acao(["https://app.example"], True{}, "https://app.example")
    == "https://app.example" : String}
