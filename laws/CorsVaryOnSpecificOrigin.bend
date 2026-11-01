import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Vary is set when ACAO is a specific origin
law cors_vary_specific:
  {Cors.cors.vary("https://app.example") == True{} : Bool}
