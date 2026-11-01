import Base
import ../src/http.bend as Http

# LAW (RFC 6750 §2.1): a space is not a bearer token character
law token_ok_space:
  {Http.token.ok("a b") == False{} : Bool}
