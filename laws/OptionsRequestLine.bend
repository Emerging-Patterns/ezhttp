import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.3.7): OPTIONS request-line opens with OPTIONS and the path
law options_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.options_req(host, path, hs), "OPTIONS " ++ path)
    == True{} : Bool}
