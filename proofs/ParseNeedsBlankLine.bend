# proofs of laws/ParseNeedsBlankLine.bend
import Base
import ../src/http.bend as Http
import ../laws/ParseNeedsBlankLine.bend as Laws

def Laws.parse_needs_blank_line(_raw, e):
  %e : {Http.parse.cut(_)
    == Http.Torn{"the response head has no blank line after it"}
    : Http.Reply}
  {==}
