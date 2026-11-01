import Base
import ../src/http.bend as Http

# LAW: any other method keeps the response body
law get_reply_keeps_body:
  {Http.reply.for("GET", Http.Reply{200, [], "secret"})
    == Http.Reply{200, [], "secret"} : Http.Reply}
