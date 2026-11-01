import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §4): a response message opens with HTTP/1.1
law respond_opens_with_version:
  for +status: U32
  for hs: List<&2, Http.Header>
  for +body: String
  {String.starts_with(Http.respond(status, hs, body), "HTTP/1.1 ")
    == True{} : Bool}
