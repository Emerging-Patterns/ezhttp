import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.5.5): 404 Not Found
law reason_404:
  {Http.reason(404) == "Not Found" : String}
