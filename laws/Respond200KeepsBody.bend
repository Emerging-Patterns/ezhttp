import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.3.1): a 200 response keeps its body
law respond_200_keeps_body:
  {Http.respond.of(Http.Reply{200, [], "ok"}) == Http.respond(200, [], "ok")
    : String}
