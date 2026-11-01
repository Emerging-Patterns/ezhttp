import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): DELETE is not safe
law method_safe_delete:
  {Http.method.safe("DELETE") == False{} : Bool}
