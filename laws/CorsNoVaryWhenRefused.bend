import Base
import ../src/cors.bend as Cors

# LAW (Fetch CORS): no Vary when ACAO is empty (the origin was refused)
law cors_vary_empty:
  for acao: String
  for e: {True{} == String.is_empty(acao) : Bool}
  {Cors.cors.vary(acao) == False{} : Bool}
