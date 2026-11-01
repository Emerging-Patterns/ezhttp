import Base
import ../src/http.bend as Http

# LAW: DELETE is idempotent
law method_idempotent_delete:
  {Http.method.idempotent("DELETE") == True{} : Bool}
