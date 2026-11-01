import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): PUT is not safe
law method_safe_put:
  {Http.method.safe("PUT") == False{} : Bool}
