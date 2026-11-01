import Base
import ../src/http.bend as Http

# LAW: POST is not idempotent
law method_idempotent_post:
  {Http.method.idempotent("POST") == False{} : Bool}
