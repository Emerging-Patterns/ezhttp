import Base
import ../src/http.bend as Http

# LAW: a bad request show is marked
law ask_show_bad_is_marked:
  for why: String
  {String.starts_with(Http.ask.show(Http.Bad{why}), "bad ") == True{} : Bool}
