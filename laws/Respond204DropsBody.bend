import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.3.5): a 204 response is written with an empty body
law respond_204_drops_body:
  {Http.respond.of(Http.Reply{204, [], "nope"}) == Http.respond(204, [], "")
    : String}
