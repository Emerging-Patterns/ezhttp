import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.2): GET is idempotent
law method_idempotent_get:
  {Http.method.idempotent("GET") == True{} : Bool}
