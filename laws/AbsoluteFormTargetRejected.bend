# For every method, target, header lines and body, a request-target that
# does not start with `/` and is not `*` (absolute-form such as
# `http://example.com/a`, or a bare `relative` path) is not origin-form, and
# the request is bad (RFC 9112 §3.2).
import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.1, §3.2.2): a target with no leading `/` that is not `*`
# is rejected
law ask_rejects_absolute_form:
  for +method: String
  for +target: String
  for +ls: List<&2, String>
  for body: String
  for es: {False{} == String.starts_with(target, "/") : Bool}
  for ea: {False{} == String.eq(target, "*") : Bool}
  {Http.ask.line(method, target, ls, body)
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
