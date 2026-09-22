# ezhttp/json: optional JSON helpers. HTTP messages stay text and octets.
# This module is the only one that imports ezjson. Request, Reply, and the
# client Response do not.
import Base
import 0xce326a73bca73cdb726972cee5bd76d4/main.bend as Ezjson
import 0xce326a73bca73cdb726972cee5bd76d4/value.bend as Value
import ./body.bend as Body

# a JSON value as a UTF-8 text body
def json.body(j: Value.Json) -> Body.Body:
  Body.body.text(Ezjson.print(j))

# text as JSON, or None when it is not JSON
def json.parse(s: String) -> Maybe<&2, Value.Json>:
  Ezjson.parse(s)

# the string inside a parsed value, or None when it is absent or not a string
def json.as_str(m: Maybe<&2, Value.Json>) -> Maybe<&2, String>:
  match m:
    case None{}:
      None{}
    case Some{j}:
      Ezjson.as_str(j)
