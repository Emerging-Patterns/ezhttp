import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Vary is not set for `*`
law cors_vary_star:
  {Cors.cors.vary("*") == False{} : Bool}
