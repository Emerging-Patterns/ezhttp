# For every method, target, header lines and body, a target that starts
# with `/` is origin-form (RFC 9112 §3.2.1): it is accepted exactly as
# written, its query included, and the request goes on to its header
# fields and framing.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.1): an origin-form target is kept as written
law ask_origin_form_keeps_query:
  for +method: String
  for +target: String
  for +ls: List<&2, String>
  for body: String
  for e: {True{} == String.starts_with(target, "/") : Bool}
  {Http.ask.line(method, target, ls, body)
    == Http.ask.frame(method, target, Http.head.list(ls),
      Http.head.go(ls, "transfer-encoding"),
      Http.head.values(ls, "content-length"), body) : Http.Request}
