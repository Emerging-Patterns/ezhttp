import Base
import ../src/http.bend as Http

# LAW: a lower-case get is not the safe method GET
law method_safe_get_lower:
  {Http.method.safe("get") == False{} : Bool}
