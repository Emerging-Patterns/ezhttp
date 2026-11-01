import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.5.6): 405 Method Not Allowed
law reason_405:
  {Http.reason(405) == "Method Not Allowed" : String}
