import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): OPTIONS is safe
law method_safe_options:
  {Http.method.safe("OPTIONS") == True{} : Bool}
