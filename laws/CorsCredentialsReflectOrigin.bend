import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): with credentials, an allowed origin is reflected as ACAO,
# never `*`, whether it is allowed by `*` or by name
law cors_credentials_reflect_origin:
  for +os: List<&2, String>
  for +origin: String
  for e: {True{} == Cors.cors.allowed(os, origin) : Bool}
  {Cors.cors.acao(os, True{}, origin) == origin : String}
