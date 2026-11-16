import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): without `*` and without credentials, an origin on the
# allow-list is reflected as ACAO
law cors_explicit_origin:
  for +os: List<&2, String>
  for +origin: String
  for +e1: {False{} == Cors.cors.star(os) : Bool}
  for e2: {True{} == Cors.cors.hit(origin, os) : Bool}
  {Cors.cors.acao(os, False{}, origin) == origin : String}
