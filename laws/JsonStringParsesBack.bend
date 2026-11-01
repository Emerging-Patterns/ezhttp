import Base
import ../src/json.bend as Json

# LAW: a JSON string parses back to that string
law json_parse_string:
  {Json.json.as_str(Json.json.parse("\"hi\"")) == Some{"hi"} : Maybe<&2, String>}
