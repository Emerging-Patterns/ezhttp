import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §4): 200 uses the OK reason-phrase
law reason_200:
  {Http.reason(200) == "OK" : String}
