import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): when the origin gets no ACAO (refused, or missing), the
# handler's reply is left unchanged
law cors_simple_refused:
  for +origins: List<&2, String>
  for methods: List<&2, String>
  for headers: List<&2, String>
  for +credentials: Bool
  for max_age: String
  for +expose: List<&2, String>
  for +origin: String
  for reply: Http.Reply
  for e: {True{} == String.is_empty(Cors.cors.acao(origins, credentials, origin)) : Bool}
  {Cors.cors.simple(Cors.Cfg{origins, methods, headers, credentials, max_age, expose}, origin, reply)
      == reply : Http.Reply}
