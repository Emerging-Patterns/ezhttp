# proofs of laws/AskNeedsBlankLine.bend
import Base
import ../src/http.bend as Http
import ../laws/AskNeedsBlankLine.bend as Laws

def Laws.ask_needs_blank_line(_raw, e):
  %e : {Http.ask.cut(_)
    == Http.Bad{"the request head has no blank line after it"}
    : Http.Request}
  {==}
