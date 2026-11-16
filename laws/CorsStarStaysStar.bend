import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): an allow-list holding `*` answers any origin with `*` when
# credentials are off
law cors_star_without_credentials:
  for +os: List<&2, String>
  for +origin: String
  for +e: {True{} == Cors.cors.star(os) : Bool}
  {Cors.cors.acao(os, False{}, origin) == "*" : String}
