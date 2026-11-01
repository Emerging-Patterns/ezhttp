import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): HEAD is safe
law method_safe_head:
  {Http.method.safe("HEAD") == True{} : Bool}
