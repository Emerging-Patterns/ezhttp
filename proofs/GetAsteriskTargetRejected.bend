# proofs of laws/GetAsteriskTargetRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/GetAsteriskTargetRejected.bend as Laws

def Laws.ask_get_asterisk_rejected(method, ls, body, e):
  %e : {Http.ask.origin(method, "*", ls, body, _)
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
  {==}
