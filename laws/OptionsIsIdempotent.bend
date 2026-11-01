import Base
import ../src/http.bend as Http

# LAW: OPTIONS is idempotent because it is safe
law method_idempotent_options:
  {Http.method.idempotent("OPTIONS") == True{} : Bool}
