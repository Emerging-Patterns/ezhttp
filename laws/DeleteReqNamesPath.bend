import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.3.5): DELETE request-line opens with DELETE and the path
law delete_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.delete_req(host, path, hs, body), "DELETE " ++ path)
    == True{} : Bool}
