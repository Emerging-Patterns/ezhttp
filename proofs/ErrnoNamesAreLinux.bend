# proofs of laws/ErrnoNamesAreLinux.bend
import Base
import ../src/wirespec.bend as Spec
import ../laws/ErrnoNamesAreLinux.bend as Laws
import ./lemmas/BaseEqualities.bend as M1

def Laws.errno_names(_n):
  {==}

def Laws.errno_or_none(s, e):
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      M1.eq.bit.absurd(&2, {Spec.wire.errno.or(SCon{h, t}) == "errno" : String},
        Equal.sym(Bool, True{}, False{}, e))

def Laws.errno_or_named(s, e):
  match s:
    case SNil{}:
      M1.eq.bit.absurd(&2, {Spec.wire.errno.or(SNil{}) == SNil{} : String}, e)
    case SCon{h, t}:
      {==}
