# For every text, `json.parse` is ezjson's parse, and `json.as_str` reads
# its result: text ezjson does not parse as JSON (such as `nope`) is none,
# and text that parses to a value gives that value's string, or none when
# it is not a string (so `"\"hi\""` gives `hi`). What ezjson parses is
# ezjson's guarantee (trusted here).
import Base
import ../src/json.bend as Json
import ezjson@1.2.0.0/main.bend as Ezjson
import ezjson@1.2.0.0/src/value.bend as Value

# LAW: text that is not JSON is none
law json_parse_rejects:
  for s: String
  for e: {Ezjson.parse(s) == None{} : Maybe<&2, Value.Json>}
  {Json.json.as_str(Json.json.parse(s)) == None{} : Maybe<&2, String>}

# LAW: text that parses to a value gives that value's string
law json_parse_string:
  for s: String
  for j: Value.Json
  for e: {Ezjson.parse(s) == Some{j} : Maybe<&2, Value.Json>}
  {Json.json.as_str(Json.json.parse(s)) == Ezjson.as_str(j)
    : Maybe<&2, String>}
