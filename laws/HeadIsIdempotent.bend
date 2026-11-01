import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.2): HEAD is idempotent
law method_idempotent_head:
  {Http.method.idempotent("HEAD") == True{} : Bool}
