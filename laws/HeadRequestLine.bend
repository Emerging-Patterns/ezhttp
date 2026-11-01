import Base
import ../src/http.bend as Http

# LAW: HEAD request-line opens with HEAD and the path (RFC 9110 §9.3.2)
law head_req_names_path:
  for +host: String
  for +path: String
  for hs: List<&2, Http.Header>
  {String.starts_with(Http.head_req(host, path, hs), "HEAD " ++ path)
    == True{} : Bool}
