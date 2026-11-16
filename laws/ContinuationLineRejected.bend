# For every header line with no colon, such as an obs-fold continuation
# line (` folded`), the line gives no field (RFC 9112 §5.1, §5.2).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §5.2): a line with no colon is not a field
law head_line_rejects_continuation:
  for h: String
  for e: {Http.NoCut{} == Http.divide(h, ":") : Http.Cut}
  {Http.head.line(h) == None{} : Maybe<&2, Http.Header>}
