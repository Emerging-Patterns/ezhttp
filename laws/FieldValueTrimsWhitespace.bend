# For every header line that has a colon, the field is the text before the
# first colon, as written, and the value is the text after it with
# surrounding whitespace trimmed (RFC 9112 §5.1), when the trimmed value
# holds no line break (laws/ObsFoldRejected.bend).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §5.1): a field value is trimmed of surrounding whitespace
law head_line_trims:
  for h: String
  for +before: String
  for +after: String
  for e: {Http.Cut{before, after} == Http.divide(h, ":") : Http.Cut}
  for ef: {False{} == Http.field.folded(String.trim(after)) : Bool}
  {Http.head.line(h) == Some{Http.H{before, String.trim(after)}}
    : Maybe<&2, Http.Header>}
