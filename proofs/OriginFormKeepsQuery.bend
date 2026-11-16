# proofs of laws/OriginFormKeepsQuery.bend
import Base
import ../src/http.bend as Http
import ../laws/OriginFormKeepsQuery.bend as Laws

def Laws.ask_origin_form_keeps_query(method, target, ls, body, e):
  %e : {Http.ask.origin(method, target, ls, body,
    Http.target.form(method, target, _))
    == Http.ask.frame(method, target, Http.head.list(ls),
      Http.head.go(ls, "transfer-encoding"),
      Http.head.values(ls, "content-length"), body) : Http.Request}
  {==}
