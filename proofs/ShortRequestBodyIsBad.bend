# proofs of laws/ShortRequestBodyIsBad.bend
import Base
import ../src/http.bend as Http
import ../laws/ShortRequestBodyIsBad.bend as Laws

def Laws.ask_clen_short(method, target, hs, n, body, e):
  %e : {Http.ask.short(method, target, hs, n, body, _)
    == Http.Bad{"the request body stopped before its Content-Length"}
    : Http.Request}
  {==}
