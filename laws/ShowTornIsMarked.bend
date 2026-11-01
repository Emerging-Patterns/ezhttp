import Base
import ../src/http.bend as Http

# LAW: a torn response says so before it says anything else
law show_torn_is_marked:
  for why: String
  {String.starts_with(Http.show(Http.Torn{why}), "torn ") == True{} : Bool}
