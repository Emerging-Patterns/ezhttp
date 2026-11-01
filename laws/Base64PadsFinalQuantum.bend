import Base
import ../src/b64.bend as B64

# LAW (RFC 4648 §4): at the end of the input, the quantum in progress is
# written out with its padding
law b64_go_end:
  for phase: B64.Phase
  {B64.b64.go([], phase) == B64.b64.end(phase) : String}
