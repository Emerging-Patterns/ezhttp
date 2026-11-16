# For every header line that gives a field and every list of lines after
# it, the request's header fields are that field, its name spelled exactly
# as the line wrote it (field names are compared case-insensitively, RFC
# 9110 §5.1, but never rewritten), and then the fields of the other lines.
import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1): a field's name is kept as written
law ask_keeps_field_name_spelling:
  for h: String
  for t: List<&2, String>
  for +before: String
  for +after: String
  for e: {Http.Cut{before, after} == Http.divide(h, ":") : Http.Cut}
  for ef: {False{} == Http.field.folded(String.trim(after)) : Bool}
  {Http.head.list(h <> t)
    == Http.H{before, String.trim(after)} <> Http.head.list(t)
    : List<&2, Http.Header>}
