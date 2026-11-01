import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.6.1): 500 Internal Server Error
law reason_500:
  {Http.reason(500) == "Internal Server Error" : String}
