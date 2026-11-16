# proofs of laws/RequestDisagreeingContentLengthsRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestDisagreeingContentLengthsRejected.bend as Laws

def Laws.clen_disagree(v, _w, rest, e):
  %e : {Http.clen.agree.step(_, _u => Http.clen.agree.go(rest, v))
    == False{} : Bool}
  {==}

def Laws.ask_rejects_disagreeing_cl(method, target, hs, te, lens, body, e):
  %e : {Http.ask.agree(method, target, hs, te, lens, body, _)
    == Http.Bad{"Content-Length values disagree"} : Http.Request}
  {==}
