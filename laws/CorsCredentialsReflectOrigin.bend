import Base
import ../src/cors.bend as Cors

# --- Fetch CORS (https://fetch.spec.whatwg.org/#cors-protocol) ---

# LAW (Fetch CORS): credentials reflect the request origin, never `*`
law cors_credentials_reflect_origin:
  {Cors.cors.acao(["*"], True{}, "https://app.example")
    == "https://app.example" : String}
