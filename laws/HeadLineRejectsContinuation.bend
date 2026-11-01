import Base
import ../src/http.bend as Http

# LAW: a continuation line with no colon is not a field
law head_line_rejects_continuation:
  {Http.head.line(" folded") == None{} : Maybe<&2, Http.Header>}
