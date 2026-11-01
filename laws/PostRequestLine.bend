import Base
import ../src/http.bend as Http

# LAW: POST request-line opens with POST and the path
law post_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.post_req(host, path, hs, body), "POST " ++ path)
    == True{} : Bool}
