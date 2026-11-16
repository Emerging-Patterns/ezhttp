# For every header line that has a colon, a value that still holds a CR or
# LF once trimmed is obs-fold (RFC 9112 §5.2), and the line gives no field.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §5.2): a folded field value is refused
law head_line_rejects_obs_fold:
  for h: String
  for +before: String
  for +after: String
  for e: {Http.Cut{before, after} == Http.divide(h, ":") : Http.Cut}
  for ef: {True{} == Http.field.folded(String.trim(after)) : Bool}
  {Http.head.line(h) == None{} : Maybe<&2, Http.Header>}
