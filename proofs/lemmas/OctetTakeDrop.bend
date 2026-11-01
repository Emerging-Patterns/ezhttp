# octets taken and dropped are String.take and String.drop
import Base
import ../../src/http.bend as Http
import ../../laws/OneOctetPerChar.bend as L1

# --- octets after a prefix ---

# the first |b| characters of b ++ r are b
def take_prefix(b: String, r: String)
  -> {String.take(String.append(b, r), String.length(b)) == b : String}:
  match b:
    case SNil{}:
      match r:
        case SNil{}:
          {==}
        case SCon{h, t}:
          {==}
    case SCon{h, t}:
      Equal.cong(String, String, x => SCon{h, x},
        String.take(String.append(t, r), String.length(t)), t,
        take_prefix(t, r))

def L1.octs_take(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      match n:
        case 0n:
          {==}
        case 1n+k:
          match k:
            case 0n:
              Equal.cong(String, String, x => SCon{h, x}, Http.octs.take(t, 0n),
                String.take(t, 0n), L1.octs_take(t, 0n))
            case 1n+j:
              Equal.cong(String, String, x => SCon{h, x},
                Http.octs.take(t, 1n+j), String.take(t, 1n+j),
                L1.octs_take(t, 1n+j))

def L1.octs_drop(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      match n:
        case 0n:
          {==}
        case 1n+k:
          match k:
            case 0n:
              L1.octs_drop(t, 0n)
            case 1n+j:
              L1.octs_drop(t, 1n+j)
