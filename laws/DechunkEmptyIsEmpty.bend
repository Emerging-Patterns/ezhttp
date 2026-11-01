import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): an empty chunked body decodes to empty
law dechunk_empty:
  {Http.dechunk("") == "" : String}
