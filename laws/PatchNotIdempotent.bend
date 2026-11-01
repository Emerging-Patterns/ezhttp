import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.2): PATCH is not one of the idempotent methods we name
law method_idempotent_patch:
  {Http.method.idempotent("PATCH") == False{} : Bool}
