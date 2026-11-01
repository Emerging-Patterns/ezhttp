# a text's count of octets is its length
import Base
import ../../src/http.bend as Http
import ../../laws/OneOctetPerChar.bend as L1

def L1.octs_len(s):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      Equal.cong(Nat, Nat, x => 1n+x, Http.octs.len(t), String.length(t),
        L1.octs_len(t))
