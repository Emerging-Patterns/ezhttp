import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): no Vary when ACAO is `*`
law cors_vary_star:
  for acao: String
  for e: {True{} == String.eq(acao, "*") : Bool}
  {Cors.cors.vary(acao) == False{} : Bool}
