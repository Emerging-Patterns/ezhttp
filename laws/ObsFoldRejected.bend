import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §5.2): a field value that still holds obs-fold is rejected
law head_line_rejects_obs_fold:
  {Http.head.line("A: b\r\n c") == None{} : Maybe<&2, Http.Header>}
