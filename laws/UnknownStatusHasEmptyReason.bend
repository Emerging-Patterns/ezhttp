import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15): a status we do not name has an empty reason-phrase
law reason_unknown_empty:
  {Http.reason(418) == "" : String}
