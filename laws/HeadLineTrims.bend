import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.5): OWS around a field value is trimmed
law head_line_trims:
  {Http.head.line("A:  b  ") == Some{Http.H{"A", "b"}} : Maybe<&2, Http.Header>}
