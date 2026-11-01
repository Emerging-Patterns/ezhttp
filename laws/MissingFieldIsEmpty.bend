import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §5.1): a missing field looks up as empty
law headers_find_missing:
  {Http.headers.find([], "host") == "" : String}
