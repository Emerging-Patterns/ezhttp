# proofs of laws/PostRequestLine.bend
import Base
import ../src/http.bend as Http
import ../laws/PostRequestLine.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.post_req_names_path(host, path, hs, body):
  +payload = body
  M1.eq.starts_append(path,
    " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, payload))
      ++ "\r\n" ++ payload)
