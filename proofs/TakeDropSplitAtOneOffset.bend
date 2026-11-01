# proofs of laws/TakeDropSplitAtOneOffset.bend
import Base
import ../src/http.bend as Http
import ../laws/TakeDropSplitAtOneOffset.bend as Laws

# LAW: one step of the UTF-8 partition
law utf8_split.arm:
  for -h: Char
  for -t: String
  for -m: Nat
  for b: Bool
  for ih: {String.append(Http.octs.take(t, m), Http.octs.drop(t, m)) == t : String}
  {String.append(
    Http.octs.take.step(b, h, _u => Http.octs.take(t, m)),
    Http.octs.drop.step(b, h, t, _u => Http.octs.drop(t, m))) == SCon{h, t} : String}

def utf8_split.arm(h, t, m, b, ih):
  match b:
    case True{}:
      {==}
    case False{}:
      Equal.cong(String, String, x => SCon{h, x},
        String.append(Http.octs.take(t, m), Http.octs.drop(t, m)), t, ih)

def Laws.utf8_split(s, n):
  match s:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      utf8_split.arm(h, t, Nat.sub(n, Http.octs.width(Char.to_u32(h))),
        Nat.is_lt(n, Http.octs.width(Char.to_u32(h))),
        Laws.utf8_split(t, Nat.sub(n, Http.octs.width(Char.to_u32(h)))))
