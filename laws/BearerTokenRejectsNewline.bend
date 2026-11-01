import Base
import ../src/http.bend as Http

# LAW (RFC 6750 §2.1): a newline is not a bearer token character
law token_ok_newline:
  {Http.token.ok("a\nb") == False{} : Bool}
