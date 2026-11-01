# proofs of laws/RequestNamesMethod.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestNamesMethod.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.request_names_method(method, host, path, hs, body):
  M1.eq.starts_append(method,
    " " ++ path ++ " HTTP/1.1\r\n"
      ++ Http.headers.lines(Http.request.fields(host, hs, body))
      ++ "\r\n" ++ body)
