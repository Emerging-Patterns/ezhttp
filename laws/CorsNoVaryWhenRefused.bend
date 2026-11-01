import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Vary is not set when the origin was refused
law cors_vary_empty:
  {Cors.cors.vary("") == False{} : Bool}
