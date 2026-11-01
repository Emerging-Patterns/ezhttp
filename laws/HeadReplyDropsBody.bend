import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §9.3.2): a HEAD response is written with an empty body
law head_reply_drops_body:
  {Http.reply.for("HEAD", Http.Reply{200, [], "secret"})
    == Http.Reply{200, [], ""} : Http.Reply}
