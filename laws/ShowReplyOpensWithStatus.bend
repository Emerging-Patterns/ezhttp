import Base
import ../src/http.bend as Http

# LAW: a reply opens with the status it holds
law show_reply_opens_with_status:
  for +status: U32
  for hs: List<&2, Http.Header>
  for body: String
  {String.starts_with(Http.show(Http.Reply{status, hs, body}), U32.show(status))
    == True{} : Bool}
