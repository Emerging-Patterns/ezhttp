import Base
import ../src/http.bend as Http

# LAW: GET request-line opens with GET and the path
law get_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.get_req(host, path, hs), "GET " ++ path)
    == True{} : Bool}
