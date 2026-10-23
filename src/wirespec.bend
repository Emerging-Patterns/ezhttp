# ezhttp/src/wirespec: the text the wire effect reads, and what its answer
# means, pure. Kept apart from wire.bend (the effect) so the proof gate can
# import it.
#
# Spec: scheme, host, port each on their own line; everything after the third
# newline is the request verbatim. The scheme line may carry a timeout after a
# space: 32 binary digits, least significant first, in milliseconds. A scheme
# line with no timeout means 60000 ms. SPEC.md HTTP-CLI lists what is
# guaranteed.
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

# --- the timeout ---

# the timeout a spec with none carries: 60 s, in milliseconds
def wire.ms.dflt() -> U32:
  60000

# one bit as a binary digit
def wire.bit(b: Bool) -> Char:
  match b:
    case True{}:
      '1'
    case False{}:
      '0'

# a word as binary digits, least significant first
def wire.bits(n: Nat, w: Word(n)) -> String:
  match n:
    case 0n:
      SNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          SCon{wire.bit(b), wire.bits(p, t)}

# binary digits, least significant first, as a word; a missing digit is 0
def wire.bits.read(n: Nat, s: String) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match s:
        case SNil{}:
          WCon{False{}, wire.bits.read(p, SNil{})}
        case SCon{c, t}:
          WCon{Char.is_eq(c, '1'), wire.bits.read(p, t)}

# a timeout as the scheme line carries it
def wire.ms.text(ms: U32) -> String:
  match ms:
    case U32{w}:
      wire.bits(32n, w)

# the first line of a timed spec: the scheme, a space, the timeout
def wire.head(secure: Bool, ms: U32) -> String:
  wire.scheme(secure) ++ " " ++ wire.ms.text(ms)

# the lines after the first: host, port, then the request verbatim
def wire.rest(host: String, port: U32, req: String) -> String:
  host ++ "\n" ++ U32.show(port) ++ "\n" ++ req

# the spec the effect reads, with a timeout in milliseconds
def wire.spec.timed(secure: Bool, ms: U32, host: String, port: U32,
  req: String) -> String:
  wire.head(secure, ms) ++ "\n" ++ wire.rest(host, port, req)

# the timeout after the scheme word, or the default when there is none
def wire.ms.words(ws: List<&2, String>) -> U32:
  match ws:
    case []:
      wire.ms.dflt()
    case _ <> []:
      wire.ms.dflt()
    case _ <> (bits <> _):
      U32{wire.bits.read(32n, bits)}

# the first line of a spec
def wire.line(ls: List<&2, String>) -> String:
  match ls:
    case []:
      ""
    case l <> _:
      l

# the timeout the effect reads from a spec, in milliseconds
def wire.ms(spec: String) -> U32:
  wire.ms.words(String.split(wire.line(String.split(spec, '\n')), ' '))

# --- the answer ---

# the wire status for an exchange that ran out of time (curl's
# CURLE_OPERATION_TIMEDOUT)
def wire.late() -> U32:
  28

# what a failed exchange is reported as: a timeout is marked, any other
# failure's reason is kept as it is
def wire.why.of(why: String, late: Bool) -> String:
  match late:
    case True{}:
      "timed out: " ++ why
    case False{}:
      why

# a failed exchange's status and reason as the reason the client reports
def wire.why(code: Maybe<&2, U32>, why: String) -> String:
  match code:
    case None{}:
      why
    case Some{n}:
      wire.why.of(why, U32.is_eq(n, wire.late()))

# whether a reported reason is a timeout
def wire.timed_out(why: String) -> Bool:
  String.starts_with(why, "timed out: ")
