import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.3.4): PUT request-line opens with PUT and the path
law put_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.put_req(host, path, hs, body), "PUT " ++ path)
    == True{} : Bool}
