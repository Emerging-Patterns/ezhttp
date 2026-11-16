# For every JSON value, its body (`json.body`) is the text body of its
# compact encoding (ezjson's `print`), so a JSON string `"hi"` is the text
# body `"\"hi\""`. The HTTP types stay text (the body is not a JSON value).
import Base
import ../src/body.bend as Body
import ../src/json.bend as Json
import ezjson@1.5.0.0/main.bend as Ezjson
import ezjson@1.5.0.0/src/value.bend as Value

# LAW: a JSON value is a text body of its compact encoding
law json_string_is_text_body:
  for j: Value.Json
  {Json.json.body(j) == Body.body.text(Ezjson.print(j)) : Body.Body}
