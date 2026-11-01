import Base
import ../src/json.bend as Json

# LAW: text that is not JSON is none
law json_parse_rejects:
  {Json.json.as_str(Json.json.parse("nope")) == None{} : Maybe<&2, String>}
