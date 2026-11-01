# proofs of laws/HeadRequestLine.bend
import Base
import ../src/http.bend as Http
import ../laws/HeadRequestLine.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.head_req_names_path(host, path, hs):
  M1.eq.starts_append(path,
    " HTTP/1.1\r\n" ++ Http.headers.lines(Http.request.fields(host, hs, ""))
      ++ "\r\n")
