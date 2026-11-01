import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.5.1): 400 Bad Request
law reason_400:
  {Http.reason(400) == "Bad Request" : String}
