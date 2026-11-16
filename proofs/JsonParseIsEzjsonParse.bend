# proofs of laws/JsonParseIsEzjsonParse.bend
import Base
import ../src/json.bend as Json
import ezjson@1.2.0.0/main.bend as Ezjson
import ezjson@1.2.0.0/src/value.bend as Value
import ../laws/JsonParseIsEzjsonParse.bend as Laws

def Laws.json_parse_rejects(s, e):
  Equal.cong(Maybe<&2, Value.Json>, Maybe<&2, String>,
    x => Json.json.as_str(x), Ezjson.parse(s), None{}, e)

def Laws.json_parse_string(s, j, e):
  Equal.cong(Maybe<&2, Value.Json>, Maybe<&2, String>,
    x => Json.json.as_str(x), Ezjson.parse(s), Some{j}, e)
