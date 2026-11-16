import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): Vary is set when ACAO is a specific origin (not `*`, not
# empty)
law cors_vary_specific:
  for acao: String
  for e1: {False{} == String.eq(acao, "*") : Bool}
  for e2: {False{} == String.is_empty(acao) : Bool}
  {Cors.cors.vary(acao) == True{} : Bool}
