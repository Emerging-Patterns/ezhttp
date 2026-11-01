import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.3.5): 204 No Content
law reason_204:
  {Http.reason(204) == "No Content" : String}
