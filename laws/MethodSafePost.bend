import Base
import ../src/http.bend as Http

# LAW: POST is not safe
law method_safe_post:
  {Http.method.safe("POST") == False{} : Bool}
