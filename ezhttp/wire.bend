# ezhttp/wire: one request out and one response back. TLS and DNS stay in
# the effect (OpenSSL via dlopen); this module does not re-specify TLS.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim. Answer: status on the first line, then text
# ("0" and the raw response, or a non-zero code and the reason).
import Base

# the exchange
def ezwire.talk(spec: String) -> IO(String):
  import "./effs/wire.c"
  import "./effs/wire.js"

# the word the effect reads for a scheme that wants TLS
def wire.scheme(secure: Bool) -> String:
  match secure:
    case True{}:
      "tls"
    case False{}:
      "tcp"

# the spec the effect reads
def wire.spec(secure: Bool, host: String, port: U32, req: String) -> String:
  wire.scheme(secure) ++ "\n" ++ host ++ "\n" ++ U32.show(port) ++ "\n" ++ req

# a request sent to a host and its whole answer read back
def wire.talk(secure: Bool, host: String, port: U32, req: String) -> IO(String):
  ezwire.talk(wire.spec(secure, host, port, req))
