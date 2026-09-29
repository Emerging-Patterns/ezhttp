# ezhttp/src/wirespec: the text the wire effect reads, pure. Kept apart from
# wire.bend (the effect) so the proof gate can import it.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim.
import Base

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
