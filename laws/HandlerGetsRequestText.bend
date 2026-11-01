# For every request that parses, the server calls the handler with that
# request as text (`step.text`): its method, target, header names and values
# and body each decoded from the octets received as UTF-8
# (laws/Utf8DecodesWithReplacement.bend, laws/OctetsDecodeAsUtf8.bend), and
# otherwise unchanged.
import Base
import ../src/http.bend as Http
import ../src/step.bend as Step
import ../src/qs.bend as Qs

# LAW: a request that parses goes to the handler exactly as it was parsed
law step_call:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for body: String
  {Step.step.of(Http.Request{method, target, hs, body})
    == Step.Call{Http.Request{method, target, hs, body}} : Step.Step}

# LAW: a request is handed on as text, each part decoded
law step_text:
  for method: String
  for target: String
  for hs: List<&2, Http.Header>
  for body: String
  {Step.step.text(Http.Request{method, target, hs, body})
    == Http.Request{Qs.octets.text(method), Qs.octets.text(target),
      Qs.octets.headers(hs), Qs.octets.text(body)} : Http.Request}
