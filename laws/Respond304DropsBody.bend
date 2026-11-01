import Base
import ../src/http.bend as Http

# LAW (RFC 9110 §15.4.5): a 304 response is written with an empty body
law respond_304_drops_body:
  {Http.respond.of(Http.Reply{304, [], "nope"}) == Http.respond(304, [], "")
    : String}
