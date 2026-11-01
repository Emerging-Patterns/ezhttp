# proofs of laws/ParseNeedsStatus.bend
import Base
import ../src/http.bend as Http
import ../laws/ParseNeedsStatus.bend as Laws

def Laws.parse_needs_status(ls, body, e):
  %e : {Http.parse.status(_, ls, body)
    == Http.Torn{"the response has no status line"}
    : Http.Reply}
  {==}
