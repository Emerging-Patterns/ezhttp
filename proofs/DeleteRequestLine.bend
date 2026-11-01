# proofs of laws/DeleteRequestLine.bend
import Base
import ../src/http.bend as Http
import ../laws/DeleteRequestLine.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.delete_req_names_path(host, path, hs, body):
  +payload = body
  M1.eq.starts_append(path,
    " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, payload))
      ++ "\r\n" ++ payload)
