# For every request that parses, the handler of a `_with` serve gets it as
# text (`step.text`, laws/HandlerGetsRequestText.bend) together with its
# body's octets as they arrived (`step.octets`), and the context value the
# serve was given.
#
# also rests on: laws/HandlerGetsRequestText.bend
import Base
import ../src/http.bend as Http
import ../src/step.bend as Step

# LAW: the handler gets the body octets of the request as they arrived
law step_octets:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for body: String
  {Step.step.octets(Http.Request{method, target, hs, body}) == body : String}
