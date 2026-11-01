import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.3.2): 201 Created
law reason_201:
  {Http.reason(201) == "Created" : String}
