# proofs of laws/JoinedPiecesAreText.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/JoinedPiecesAreText.bend as Laws

law app_nil:
  for x: String
  {x ++ "" == x : String}

def app_nil(x):
  match x:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(String, String, r => SCon{h, r}, t ++ "", t, app_nil(t))

law app_assoc:
  for x: String
  for +y: String
  for +z: String
  {(x ++ y) ++ z == x ++ (y ++ z) : String}

def app_assoc(x, y, z):
  match x:
    case SNil{}:
      {==}
    case SCon{+h, +t}:
      Equal.cong(String, String, r => SCon{h, r}, (t ++ y) ++ z, t ++ (y ++ z),
        app_assoc(t, y, z))

law join_go:
  for ps: List<&2, String>
  for +acc: String
  {Spec.wire.join.go(ps, acc) == Spec.wire.joined(ps) ++ acc : String}

def join_go(ps, acc):
  match ps:
    case []:
      {==}
    case +p <> +rest:
      Equal.trans(String, Spec.wire.join.go(rest, p ++ acc),
        Spec.wire.joined(rest) ++ (p ++ acc),
        (Spec.wire.joined(rest) ++ p) ++ acc,
        join_go(rest, p ++ acc),
        Equal.sym(String, (Spec.wire.joined(rest) ++ p) ++ acc,
          Spec.wire.joined(rest) ++ (p ++ acc),
          app_assoc(Spec.wire.joined(rest), p, acc)))

def Laws.join_joined(ps):
  Equal.trans(String, Spec.wire.join.go(ps, ""), Spec.wire.joined(ps) ++ "",
    Spec.wire.joined(ps), join_go(ps, ""), app_nil(Spec.wire.joined(ps)))
