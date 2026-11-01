import Base
import ../src/http.bend as Http

# --- RFC 6750 / 7617 / 4648 credentials ---

# LAW (RFC 6750 §2.1): a token with no whitespace is acceptable
law token_ok_plain:
  {Http.token.ok("abc") == True{} : Bool}
