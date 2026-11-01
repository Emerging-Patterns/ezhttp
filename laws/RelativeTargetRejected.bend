import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.1): a request-target without a leading `/` is not
# origin-form
law ask_rejects_relative_target:
  {Http.ask("GET relative HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Bad{"the request-target is not in origin-form"} : Http.Request}
