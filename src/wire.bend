# ezhttp/src/wire: one request out and one response back. TLS and DNS stay in
# the effect (OpenSSL via dlopen); this module does not re-specify TLS.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim; the scheme line may carry a timeout
# (wirespec.bend). Answer: status on the first line, then text
# ("0" and the raw response, or a non-zero code and the reason).
import Base
import ./wirespec.bend as Spec

# the exchange
def ezwire.talk(spec: String) -> IO(String):
  import "./effs/wire.c"
  import "./effs/wire.js"

# the spec the effect reads (wirespec.bend)
def wire.spec(secure: Bool, host: String, port: U32, req: String) -> String:
  Spec.wire.spec(secure, host, port, req)

# a request sent to a host and its whole answer read back
def wire.talk(secure: Bool, host: String, port: U32, req: String) -> IO(String):
  ezwire.talk(wire.spec(secure, host, port, req))

# the same exchange, bounded by a timeout in milliseconds
def wire.talk.timed(secure: Bool, ms: U32, host: String, port: U32,
  req: String) -> IO(String):
  ezwire.talk(Spec.wire.spec.timed(secure, ms, host, port, req))
