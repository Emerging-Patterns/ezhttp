# The server's decisions live in `src/step.bend` and `src/http.bend`, which
# do no IO; `src/server.bend` runs the effects and acts on them (trusted in
# src/server.bend). Each connection is served on its own fork, so
# connections overlap. `http.serve_with`, `http.serve_io_with` and
# `http.serve_forever_with` hand the handler a context value with each
# request (`Server.Req`: the request as text and its body's octets) and take
# a reply as text, as packed octets, or streamed from a channel of octet
# chunks; `http.serve`, `http.serve_io`, `http.serve_once` and
# `http.serve_forever` are those with a text handler and no context. It
# receives a request as octets, one character each
# (laws/OneOctetPerChar.bend), so its Content-Length counts octets.
#
# For every request that does not parse, with reason `why`, the server
# answers `400` with body `why` and does not call the handler.
import Base
import ../src/http.bend as Http
import ../src/step.bend as Step

# --- the server's decisions ---

# LAW: a request that does not parse is answered 400 with its reason, and
# the handler is not called
law step_bad:
  for why: String
  {Step.step.of(Http.Bad{why}) == Step.Answer{Http.Reply{400, [], why}}
    : Step.Step}

# LAW: a bad request keeps its reason
law step_text_bad:
  for why: String
  {Step.step.text(Http.Bad{why}) == Http.Bad{why} : Http.Request}
