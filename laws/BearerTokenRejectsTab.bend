import Base
import ../src/http.bend as Http

# LAW (RFC 6750 §2.1): a tab is not a bearer token character
law token_ok_tab:
  {Http.token.ok("a\tb") == False{} : Bool}
