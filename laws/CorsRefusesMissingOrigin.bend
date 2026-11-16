import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): an origin the allow-list does not allow gets an empty ACAO
law cors_refused_origin:
  for +os: List<&2, String>
  for credentials: Bool
  for +origin: String
  for e: {False{} == Cors.cors.allowed(os, origin) : Bool}
  {Cors.cors.acao(os, credentials, origin) == "" : String}
