# proofs of laws/RequestWithBothFramingsRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/RequestWithBothFramingsRejected.bend as Laws

def Laws.ask_rejects_cl_and_te(method, target, hs, te, l, ls, body, ea, ec):
  %ea : {Http.ask.agree(method, target, hs, te, l <> ls, body, _)
    == Http.Bad{"Content-Length and Transfer-Encoding conflict"}
    : Http.Request}
  %ec : {Http.ask.te(method, target, hs, l <> ls, body, _)
    == Http.Bad{"Content-Length and Transfer-Encoding conflict"}
    : Http.Request}
  {==}
