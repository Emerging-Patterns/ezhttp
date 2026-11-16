# For every set of header lines and body, `OPTIONS *` names the server as a
# whole (RFC 9112 §3.2.4): its target `*` is accepted as written and the
# request goes on to its header fields and framing like an origin-form one.
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.4): `OPTIONS *` is accepted, its target kept
law ask_options_asterisk:
  for +ls: List<&2, String>
  for body: String
  {Http.ask.line("OPTIONS", "*", ls, body)
    == Http.ask.frame("OPTIONS", "*", Http.head.list(ls),
      Http.head.go(ls, "transfer-encoding"),
      Http.head.values(ls, "content-length"), body) : Http.Request}
