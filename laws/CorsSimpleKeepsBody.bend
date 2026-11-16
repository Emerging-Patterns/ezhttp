import Base
import ../src/http.bend as Http
import ../src/cors.bend as Cors

# LAW (Fetch CORS): when the origin gets an ACAO, a reply keeps its status and
# body and gets the simple CORS headers (credentials, Vary, Expose-Headers,
# Allow-Origin) ahead of its own
law cors_simple_reflects:
  for +origins: List<&2, String>
  for methods: List<&2, String>
  for headers: List<&2, String>
  for +credentials: Bool
  for max_age: String
  for +expose: List<&2, String>
  for +origin: String
  for status: U32
  for hs: List<&2, Http.Header>
  for body: String
  for e: {False{} == String.is_empty(Cors.cors.acao(origins, credentials, origin)) : Bool}
  {Cors.cors.simple(Cors.Cfg{origins, methods, headers, credentials, max_age, expose}, origin, Http.Reply{status, hs,
      body})
    == Http.Reply{status, List.append(&2, Http.Header,
      Cors.cors.simple_hs(Cors.cors.acao(origins, credentials, origin), credentials, expose), hs), body}
    : Http.Reply}
