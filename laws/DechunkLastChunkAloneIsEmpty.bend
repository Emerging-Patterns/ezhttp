import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §7.1): a body that is only the last chunk is empty
law dechunk_only_last:
  {Http.dechunk("0\r\n\r\n") == "" : String}
