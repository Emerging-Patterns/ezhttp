import Base
import ../src/http.bend as Http

# LAW (RFC 9112 §3.2.4): OPTIONS asterisk-form names the whole server
law ask_options_asterisk:
  {Http.ask("OPTIONS * HTTP/1.1\r\nHost: h\r\n\r\n")
    == Http.Request{"OPTIONS", "*", [Http.H{"Host", "h"}], ""} : Http.Request}
