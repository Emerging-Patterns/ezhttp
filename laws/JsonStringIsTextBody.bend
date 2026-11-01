import Base
import ../src/body.bend as Body
import ../src/json.bend as Json
import 0xa81e161008ecc2f297c0a3065cb9b188/main.bend as Ezjson

# LAW: a JSON string is a text body of its compact encoding. The HTTP types
# stay text (the body is not a JSON value).
law json_string_is_text_body:
  {Json.json.body(Ezjson.str("hi")) == Body.body.text("\"hi\"") : Body.Body}
