import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.2.1): GET, HEAD, and OPTIONS are safe; `get` is not GET
law method_safe_get:
  {Http.method.safe("GET") == True{} : Bool}
