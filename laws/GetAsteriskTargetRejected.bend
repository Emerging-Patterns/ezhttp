# For every method other than OPTIONS, header lines and body, the
# asterisk-form target `*` is not accepted, so a `GET *` request is bad:
# asterisk-form is only for OPTIONS (RFC 9112 §3.2.4).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.4): `*` is rejected for every method but OPTIONS
law ask_get_asterisk_rejected:
  for +method: String
  for +ls: List<&2, String>
  for body: String
  for e: {False{} == String.eq(method, "OPTIONS") : Bool}
  {Http.ask.line(method, "*", ls, body)
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
