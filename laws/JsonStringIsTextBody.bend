import Base
import ../src/body.bend as Body
import ../src/json.bend as Json
import ezjson@1.2.0.0/main.bend as Ezjson

# LAW: a JSON string is a text body of its compact encoding. The HTTP types
# stay text (the body is not a JSON value).
law json_string_is_text_body:
  {Json.json.body(Ezjson.str("hi")) == Body.body.text("\"hi\"") : Body.Body}
