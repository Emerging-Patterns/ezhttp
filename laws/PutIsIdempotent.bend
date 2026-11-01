import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.2): PUT is idempotent
law method_idempotent_put:
  {Http.method.idempotent("PUT") == True{} : Bool}
