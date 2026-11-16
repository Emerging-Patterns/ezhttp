# proofs of laws/AbsoluteFormTargetRejected.bend
import Base
import ../src/http.bend as Http
import ../laws/AbsoluteFormTargetRejected.bend as Laws

def Laws.ask_rejects_absolute_form(method, target, ls, body, es, ea):
  %es : {Http.ask.origin(method, target, ls, body,
    Http.target.form(method, target, _))
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
  %ea : {Http.ask.origin(method, target, ls, body,
    Http.target.asterisk(method, _))
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
  {==}
