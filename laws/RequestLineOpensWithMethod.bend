import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.1): the request-line opens with the method it was given
law request_names_method:
  for +method: String
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.request(method, host, path, hs, body), method)
    == True{} : Bool}
